# 05. BUSINESS RULES

> **⚠️ IMPORTANT**: All rules in this file MUST reference states defined in [`11_state_machines.md`](./11_state_machines.md).
> State machine is the Single Source of Truth. These rules provide validation logic and business constraints ON TOP of state transitions.
>
> **Key Principles**:
> - Use `state` (not `status`) for entity states
> - State names MUST match exactly: PUBLISHED, STARTED, ENDED, ACTIVE, USED, etc.
> - Time-based rules work WITH state transitions, not against them
> - Terminal states are truly terminal unless explicitly stated otherwise

---

## AUTHENTICATION

### Google Sign-In Only (V1)

| Rule | Value |
|------|-------|
| Allowed methods | Google Sign-In only |
| Email/password | Not supported (V2) |
| Session duration | 1 hour (access token) |
| Refresh token | 30 days |
| Auto-refresh | 5 min before expiry |

### User State-Based Rules

From state machine [`11_state_machines.md`](./11_state_machines.md#user-state-machine):

```dart
// UNAUTHENTICATED state
canLogin = true
canAccessProtectedContent = false

// AUTHENTICATED state
canAccessProtectedContent = true
canEditProfile = true
canBuyTicket = true

// PROFILE_INCOMPLETE state
canAccessProtectedContent = true
canEditProfile = true
canBuyTicket = false  // Must complete profile first

// DISABLED state
canLogin = false
canAccessProtectedContent = false
```

### New User Detection

```dart
isNewUser = (accountCreated < 1 minute ago) AND (dateOfBirth == null)

// Transition: NEW → UNAUTHENTICATED → AUTHENTICATED or PROFILE_INCOMPLETE
```

**Logic**:
- If new and profile incomplete → Redirect to `/complete-profile` (PROFILE_INCOMPLETE state)
- If existing → Redirect to `/home` (AUTHENTICATED state)
- If disabled → Show error, redirect to login (DISABLED state)

---

## USER PROFILE

### Required Fields (V1)

| Field | Required? | Default |
|-------|-----------|---------|
| Name | Yes | From Google |
| Email | Yes | From Google |
| DOB | No* | null |
| Location | No* | null (Jakarta if denied) |
| Bio | No | null |
| Phone | No | null |
| Gender | No | null |

\* Required for recommendations, but can skip.

### Profile Completion State

**State Transition**: `PROFILE_INCOMPLETE → AUTHENTICATED`

**Condition**:
```dart
isProfileComplete = (dateOfBirth != null) && (location != null)

// When profile becomes complete
if (isProfileComplete) {
  user.state = AUTHENTICATED
  canBuyTicket = true
}
```

**Impact**:
- Complete → Full recommendations
- Incomplete → Limited recommendations, cannot buy tickets

### Location Handling

| Permission | Action |
|------------|--------|
| Allowed | Use GPS + geocode |
| Denied once | Show error, stay on screen |
| Denied forever | Open app settings |
| Skip | Use default (Jakarta) |

---

## EVENTS

### Event State-Based Rules

From state machine [`11_state_machines.md`](./11_state_machines.md#event-state-machine):

```dart
// DRAFT state
isVisibleToPublic = false
canRegister = false
canEdit = organizer only

// PUBLISHED state
isVisibleToPublic = true
canRegister = true  // Time-limited: now < event.startDate
canEdit = organizer only
ticketsSoldCount increases

// STARTED state
isVisibleToPublic = true
canRegister = false  // Event has started, registration closed
canCheckIn = true
ticketsSoldCount locked

// ENDED state
isVisibleToPublic = true
canRegister = false
canCheckIn = false
showResults = true

// CANCELLED state
isVisibleToPublic = false
canRegister = false
notifyAttendees = true  // Notify users event is cancelled
```

### Event Visibility Rules

```dart
// Primary visibility rule
canShowEvent = (event.state != DRAFT) && (event.state != CANCELLED)

// Past events: Show in "Past" tab only
isPastEvent = (now > event.endDate)

// Live events: Show special indicator
isLive = (event.state == STARTED)
```

**Feed Display Rules**:
- Main feed: Events in PUBLISHED or STARTED state, not ended yet
- Past tab: Events in ENDED state
- Hidden: Events in DRAFT or CANCELLED state

### UI Button State Mapping

| Event State & Condition | Button Text | Action |
|------------------------|-------------|--------|
| PUBLISHED, free, (now < startDate) | [DAFTAR] | Register for free |
| PUBLISHED, paid, (now < startDate) | [BELI TIKET] | Go to purchase |
| User has ticket, (ticket.state == ACTIVE) | [LIHAT TIKET] | Show ticket |
| STARTED | [SEDANG BERLANGSUNG] | Show live indicator |
| ENDED | [SELESAI] | Disabled, show results |
| CANCELLED | [DIBATALKAN] | Disabled, event cancelled by organizer |
| PUBLISHED, full | [HABIS] | Disabled |

### Registration Time-Based Rule

```dart
// Critical: Registration closes when event STARTED
canRegister = (event.state == PUBLISHED) && (now < event.startDate)

// When event STARTED (state transition), registration automatically closes
// This is enforced by state machine, not just time check
```

### Location-Based Display

**Nearby**: Events within 10km of user's location
**Fallback**: If location denied, show Jakarta events

---

## TICKETS

### Ticket State-Based Rules

From state machine [`11_state_machines.md`](./11_state_machines.md#ticket-state-machine):

```dart
// RESERVED state
isPurchased = true
isPaid = false
canUse = false

// ACTIVE state
isPurchased = true
isPaid = true
canUse = true

// USED state
isPurchased = true
isPaid = true
isUsed = true
canUse = false  // Terminal state

// EXPIRED state
isPurchased = true
isPaid = true
isExpired = true
canUse = false  // Terminal state
```

**⚠️ V1 Refund Policy**: All purchases are final. No refund mechanism in V1 (see [`10_non_goals.md`](./10_non_goals.md)). USED and EXPIRED are truly terminal states with NO exceptions.

### Purchase Rules

| Rule | Value |
|------|-------|
| Min per order | 1 |
| Max per order | 10 |
| Payment timeout | 15 minutes |
| Max tickets per event | No limit (V1) |

### Purchase Validation

```dart
canPurchase = (user.state == AUTHENTICATED) &&
              (event.state == PUBLISHED) &&
              (now < event.startDate) &&
              (!event.isFull)

// After successful payment: RESERVED → ACTIVE transition
```

### Sold Out Detection

```dart
isSoldOut = (event.attendeesCount >= event.capacity) ||
            (all ticket types.available == false)
```

### QR Code Rules

| Ticket State | QR Valid? | QR Action |
|--------------|-----------|-----------|
| RESERVED | No | Show "Ticket not paid yet" |
| ACTIVE | Yes | Show QR for check-in |
| USED | Yes | Show "Checked in at {time}" |
| EXPIRED | No | Show "Ticket expired" |

| Property | Value |
|----------|-------|
| Format | Alphanumeric string |
| Length | 32 chars |
| Valid from | Purchase time (when RESERVED → ACTIVE) |
| Valid until | Event end time |
| Can check-in from | Event start time |
| Can check-in until | Event end time |

### Check-In Rules

```dart
// Validation uses state, not status
canCheckIn = (ticket.state == ACTIVE) &&
             (now >= event.startDate) &&
             (now <= event.endDate) &&
             (!ticket.isUsed)

// After successful check-in: ACTIVE → USED transition
```

**Error Messages**:
| Condition | Message |
|-----------|---------|
| ticket.state != ACTIVE | "Tiket tidak valid" |
| ticket.state == USED | "Kamu sudah check-in" |
| now < event.startDate | "Check-in dibuka pada {start time}" |
| now > event.endDate | "Tiket sudah kadaluarsa" |
| Invalid QR | "QR code tidak valid" |

---

## POSTS

### Post State-Based Rules

From state machine [`11_state_machines.md`](./11_state_machines.md#post-state-machine):

```dart
// DRAFT state
isVisibleToOthers = false
canEdit = true
canDelete = true

// PUBLISHED state
isVisibleToOthers = true
canEdit = false
canDelete = true
canHide = true

// HIDDEN state
isVisibleToOthers = false
canEdit = false
canDelete = true
canUnhide = true

// DELETED state
isDeleted = true
isVisibleToOthers = false
canEdit = false
canDelete = false
```

### Post Visibility

```dart
canShowPost = (post.user.state != DISABLED) &&
             (post.state == PUBLISHED)
```

### Content Rules

| Rule | Value |
|------|-------|
| Max length | 500 chars |
| Max photos | 10 |
| Max video | 0 (V2) |
| Tagged event | Must exist |
| Location | Free text, any city |

### Like Rules

- Can unlike own post
- Cannot like twice (toggle)
- Like count updates immediately (optimistic)

### Comment State-Based Rules

From state machine [`11_state_machines.md`](./11_state_machines.md#comment-state-machine):

```dart
// ACTIVE state
isVisible = true
canEdit = (author || within 5 minutes of creation)
canDelete = author

// HIDDEN state
isVisible = false
canEdit = false
canDelete = admin only

// DELETED state
isDeleted = true
isVisible = false
canEdit = false
canDelete = false
```

### Comment Rules

| Rule | Value |
|------|-------|
| Max length | 500 chars |
| Edit | Not supported (V1) |
| Delete | Owner only |
| Reply | Not supported (V1) |

---

## SOCIAL (FOLLOW)

### Follow State-Based Rules

From state machine [`11_state_machines.md`](./11_state_machines.md#follow-relationship-state):

```dart
// NONE state
following = false
blocked = false
canFollow = true
canBlock = true

// FOLLOWING state
following = true
blocked = false
canFollow = false
canUnfollow = true
canBlock = true

// BLOCKED state
following = false
blocked = true
canFollow = false
canUnfollow = false
canBlock = false
canUnblock = true
```

### Follow Validation

```dart
canFollow = (user.id != currentUser.id) &&
            (user.state != DISABLED) &&
            (relationship.state == NONE)

canUnfollow = (relationship.state == FOLLOWING)
```

### Unfollow Flow

**Single tap** → [MENGIKUTI] → [BATAL MENGIKUTI?]
**Double tap** → Direct unfollow

**Confirmation**: 3 seconds to cancel double-tap.

### Follower Display

**Format**:
- < 1,000: Exact number (123)
- 1K - 1M: "1.2rb", "350rb"
- > 1M: "1.5jt"

**Thousands separator**: Dot (.) not comma.

---

## FEED RANKING

### Rank Factors

| Factor | Weight |
|--------|--------|
| Location proximity | High |
| Interest match | Medium |
| Friends attending | Medium |
| Event time | Low (sooner = higher) |
| Host quality | Low |

**Feed Mix**:
- 70% nearby events
- 20% popular events
- 10% new events

**Event State Filter**:
```dart
showInFeed = (event.state == PUBLISHED || event.state == STARTED) &&
             (now < event.endDate)
```

---

## SEARCH

### Search Debounce

```
User stops typing → Wait 500ms → Send search request
```

### Search Scope

| Query | Searches In |
|-------|-------------|
| "Music" | Event titles, descriptions |
| "Jakarta" | Event locations |
| "@username" | User profiles (V2) |

**State Filter**: Only search events in PUBLISHED or STARTED state

---

## ORDER / PAYMENT

### Order State-Based Rules

From state machine [`11_state_machines.md`](./11_state_machines.md#order--payment-state-machine):

```dart
// PENDING state
orderCreated = true
waitingForPayment = true
canCancel = true
canRetry = false

// PROCESSING state
paymentInitiated = true
waitingForConfirmation = true
canCancel = false
canRetry = false

// SUCCESS state
paymentCompleted = true
ticketsIssued = true
canCancel = false
canRetry = false

// FAILED state
paymentFailed = true
canRetry = true
canCancel = false

// CANCELLED state
orderCancelled = true
canRetry = false

// EXPIRED state
paymentExpired = true
canRetry = true
```

**⚠️ V1 Refund Policy**: SUCCESS is a terminal state. All purchases are final. No refund mechanism in V1 (see [`10_non_goals.md`](./10_non_goals.md)). No exceptions, no admin overrides, no manual refunds.

### Payment Flow (Midtrans)

```
1. Create order (PENDING state)
2. Initiate payment (PENDING → PROCESSING)
3. Open Midtrans (SDK or webview)
4. User completes payment
5. Webhook → Update order status (PROCESSING → SUCCESS or FAILED)
6. Poll for status → Show result
```

### Payment Status UI

| Order State | UI Message | Action |
|-------------|------------|--------|
| PENDING | "Menunggu pembayaran" | Show payment button |
| PROCESSING | "Pembayaran diproses" | Show loading |
| SUCCESS | "Pembayaran berhasil" | Redirect to tickets |
| FAILED | "Pembayaran gagal" | Show retry button |
| EXPIRED | "Pembayaran kadaluarsa" | Show retry button |
| CANCELLED | "Pesanan dibatalkan" | Redirect to event |

### Payment Timeout

```dart
// Order expires: 15 minutes after creation
orderExpiresAt = createdAt + Duration(minutes: 15)

// Auto-transition: PENDING → EXPIRED
if (now > orderExpiresAt && order.state == PENDING) {
  order.state = EXPIRED
}
```

---

## RATE LIMITING

| Endpoint | Limit |
|----------|-------|
| All endpoints | 100 req/min |
| Create post | 10 req/min |
| Like/Unlike | 30 req/min |
| Follow/Unfollow | 30 req/min |

**Error Response**:
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Try again in {X} seconds."
  }
}
```

---

## CONTENT MODERATION

### User State Impact

When content violation found:
```dart
// First offense: Hide content
post.state = HIDDEN

// Repeat offense: Ban user
user.state = DISABLED

// DISABLED state consequences
canLogin = false
canAccessProtectedContent = false
allContentHidden = true
```

### Banned Content

- Hate speech
- Nudity
- Spam
- Illegal activities

### Reporting

| Type | Action |
|------|--------|
| Spam | Shadowban posts (state: HIDDEN) |
| Inappropriate | Hide content (state: HIDDEN) |
| Illegal | Ban user (state: DISABLED) |

---

## NOTIFICATIONS (V2)

| Trigger | Notification |
|---------|--------------|
| Event starting soon | 1 hour before |
| Ticket purchased | Immediate |
| Check-in success | Immediate |
| New follower | Immediate |
| Post like | Batched (max 1/hour) |

### Notification State Machine

From [`11_state_machines.md`](./11_state_machines.md#notification-state-machine):

```
PENDING → SENT → DELIVERED → READ
         ↓       FAILED
       CANCELLED
```

---

## DATA RETENTION

| Data Type | Retention |
|-----------|-----------|
| User data | Forever (until account deleted) |
| Posts | Forever (state: DELETED) |
| Comments | Forever (state: DELETED) |
| Tickets | 1 year after event (state: USED/EXPIRED) |
| Analytics | 90 days |

---

## IMPLEMENTATION NOTES

**Business Logic Location**:
- Use Cases: `lib/domain/usecases/`
- BLoCs: `lib/presentation/bloc/`

**State Property Naming**:
- Always use `state` (not `status`)
- Always use exact state names from `11_state_machines.md`
- Example: `ticket.state == TicketState.ACTIVE` (not `ticket.status == 'active'`)

**Example: CanCheckInUseCase**
```dart
class CanCheckInUseCase {
  bool call(Ticket ticket, Event event) {
    final now = DateTime.now().toUtc();

    // Check state (not status)
    if (ticket.state != TicketState.ACTIVE) {
      return false;
    }

    // Check time window
    if (!now.isAfter(event.startDate) || !now.isBefore(event.endDate)) {
      return false;
    }

    // Check already used (state property)
    if (ticket.isUsed) {
      return false;
    }

    return true;
  }
}
```

**Example: CanRegisterForEventUseCase**
```dart
class CanRegisterForEventUseCase {
  bool call(Event event, User user) {
    final now = DateTime.now().toUtc();

    // User state check
    if (user.state != UserState.AUTHENTICATED) {
      return false;
    }

    // Event state check
    if (event.state != EventState.PUBLISHED) {
      return false;
    }

    // Time-based check (registration closes when event STARTS)
    if (!now.isBefore(event.startDate)) {
      return false;
    }

    // Capacity check
    if (event.attendeesCount >= event.capacity) {
      return false;
    }

    return true;
  }
}
```

---

**LAST UPDATED**: 2025-01-28
**APPROVED BY**: Project Owner
**PURPOSE**: Business logic and constraints (aligned with state machines)

**Remember**: State machine defines WHAT states exist and HOW they transition. Business rules define WHEN and UNDER WHAT CONDITIONS actions can happen. Always check `11_state_machines.md` first.
