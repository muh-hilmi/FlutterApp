# 11. STATE MACHINES & LIFECYCLE

**Entity states and legal transitions. Frontend & Backend MUST follow these.**

---

## USER STATE MACHINE

### States

```
NEW → UNAUTHENTICATED → AUTHENTICATED
                     ↓
                PROFILE_INCOMPLETE
                     ↓
                   AUTHENTICATED
                     ↓
                  DISABLED
```

### Legal Transitions

| From | To | Condition |
|------|----|------------|
| NEW | UNAUTHENTICATED | User created (default) |
| UNAUTHENTICATED | AUTHENTICATED | Successful login |
| AUTHENTICATED | PROFILE_INCOMPLETE | New user, no DOB/location |
| PROFILE_INCOMPLETE | AUTHENTICATED | Completes profile |
| AUTHENTICATED | UNAUTHENTICATED | Logout |
| AUTHENTICATED | DISABLED | Banned by admin |
| DISABLED | UNAUTHENTICATED | Unbanned (manual) |

### Illegal Transitions

❌ NEW → AUTHENTICATED (must login first)
❌ AUTHENTICATED → NEW (cannot become new again)
❌ DISABLED → AUTHENTICATED (must be unbanned first)

### State Rules

```dart
// UNAUTHENTICATED
canLogin = true
canAccessProtectedContent = false

// AUTHENTICATED
canAccessProtectedContent = true
canEditProfile = true
canBuyTicket = true

// PROFILE_INCOMPLETE
canAccessProtectedContent = true
canEditProfile = true
canBuyTicket = false  // Must complete profile first
```

---

## EVENT STATE MACHINE

### States

```
DRAFT → PUBLISHED → STARTED → ENDED → CANCELLED
```

### Legal Transitions

| From | To | Condition | Who |
|------|----|------------|-----|
| DRAFT | PUBLISHED | Organizer publishes | Admin |
| PUBLISHED | CANCELLED | Organizer cancels | Organizer |
| PUBLISHED | STARTED | Event start time reached | System |
| STARTED | ENDED | Event end time reached | System |
| STARTED | CANCELLED | Organizer cancels | Organizer |
| CANCELLED | DRAFT | Re-create as draft | Organizer |
| ENDED | ARCHIVED | 30 days after event | System |

### Illegal Transitions

❌ DRAFT → STARTED (must publish first)
❌ DRAFT → ENDED (must publish first)
❌ CANCELLED → STARTED (cannot un-cancel)
❌ ENDED → STARTED (time only moves forward)
❌ ENDED → CANCELLED (too late, event already concluded)

### State Rules

```dart
// DRAFT
isVisibleToPublic = false
canRegister = false
canEdit = organizer only

// PUBLISHED
isVisibleToPublic = true
canRegister = true
canEdit = organizer only
ticketsSoldCount increases

// STARTED
isVisibleToPublic = true
canRegister = false  // Registration closes when event starts
canCheckIn = true
ticketsSoldCount locked

// ENDED
isVisibleToPublic = true
canRegister = false
canCheckIn = false
showResults = true

// CANCELLED
isVisibleToPublic = false
canRegister = false
notifyAttendees = true  // Notify users event is cancelled
```

### Time-Based Rules

```dart
// Registration (only in PUBLISHED state)
canRegister = (event.state == PUBLISHED) && (now < event.startDate)

// Check-in (only in STARTED state)
canCheckIn = (event.state == STARTED) && (now >= event.startDate) && (now <= event.endDate)

// Visibility
showEvent = (event.state != CANCELLED) && (event.state != DRAFT)
```

---

## TICKET STATE MACHINE

### States

```
RESERVED → ACTIVE → USED → EXPIRED
```

### Legal Transitions

| From | To | Condition | Who |
|------|----|------------|-----|
| RESERVED | ACTIVE | Payment successful | System |
| ACTIVE | USED | Check-in successful | System |
| ACTIVE | EXPIRED | Event end time passed | System |

### Illegal Transitions

❌ RESERVED → USED (must be ACTIVE first)
❌ USED → ACTIVE (cannot undo check-in)
❌ EXPIRED → ACTIVE (time only moves forward)
❌ Any transition to/from REFUNDED (refund not supported in V1)

### State Rules

```dart
// RESERVED
isPurchased = true
isPaid = false
canUse = false

// ACTIVE
isPurchased = true
isPaid = true
canUse = true

// USED
isPurchased = true
isPaid = true
isUsed = true
canUse = false

// EXPIRED
isPurchased = true
isPaid = true
isExpired = true
canUse = false
```

**Note**: All purchases are final. No refund mechanism in V1 (see `10_non_goals.md`).

### QR Code Rules

| State | QR Valid | QR Action |
|-------|----------|-----------|
| RESERVED | No | "Ticket not paid yet" |
| ACTIVE | Yes | Shows QR for check-in |
| USED | Yes | Shows "Checked in at {time}" |
| EXPIRED | No | "Ticket expired" |

---

## ORDER / PAYMENT STATE MACHINE

### States

```
PENDING → PROCESSING → SUCCESS
         ↓           ↓
       FAILED      EXPIRED
         ↓
       CANCELLED
```

### Legal Transitions

| From | To | Condition | Trigger |
|------|----|------------|--------|
| PENDING | PROCESSING | Payment initiated | User |
| PENDING | CANCELLED | User cancels or timeout | User/System |
| PENDING | EXPIRED | 15 minutes elapsed | System |
| PROCESSING | SUCCESS | Payment confirmed | Midtrans webhook |
| PROCESSING | FAILED | Payment declined/failed | Midtrans webhook |
| PROCESSING | PENDING | Retry initiated | System |
| FAILED | PENDING | User retries | User |

### Illegal Transitions

❌ SUCCESS → PENDING (cannot un-pay)
❌ SUCCESS → REFUNDED (refund not supported in V1)
❌ EXPIRED → PROCESSING (time only moves forward)

### State Rules

```dart
// PENDING
orderCreated = true
waitingForPayment = true
canCancel = true
canRetry = false

// PROCESSING
paymentInitiated = true
waitingForConfirmation = true
canCancel = false
canRetry = false

// SUCCESS
paymentCompleted = true
ticketsIssued = true
canCancel = false
canRetry = false

// FAILED
paymentFailed = true
canRetry = true
canCancel = false

// CANCELLED
orderCancelled = true
canRetry = false

// EXPIRED
paymentExpired = true
canRetry = true
```

**Note**: SUCCESS is a terminal state. No refund mechanism in V1 (see `10_non_goals.md`). All purchases are final.

### Time-Based Rules

```dart
// Order expires after 15 minutes
orderExpiresAt = createdAt + Duration(minutes: 15)

// Can retry
canRetry = (now < orderExpiresAt) && (state == FAILED)
```

---

## POST STATE MACHINE

### States

```
DRAFT → PUBLISHED → HIDDEN
                   ↓
                DELETED
```

### Legal Transitions

| From | To | Condition | Who |
|------|----|------------|-----|
| DRAFT | PUBLISHED | User submits | User |
| PUBLISHED | HIDDEN | User hides | User |
| HIDDEN | PUBLISHED | User un-hides | User |
| PUBLISHED | DELETED | User deletes | User |
| DELETED | DRAFT | Recreated (undo) | System |

### Illegal Transitions

❌ DELETED → PUBLISHED (cannot undelete)

### State Rules

```dart
// DRAFT
isVisibleToOthers = false
canEdit = true
canDelete = true

// PUBLISHED
isVisibleToOthers = true
canEdit = false
canDelete = true
canHide = true

// HIDDEN
isVisibleToOthers = false
canEdit = false
canDelete = true
canUnhide = true

// DELETED
isDeleted = true
isVisibleToOthers = false
canEdit = false
canDelete = false
```

---

## COMMENT STATE MACHINE

### States

```
ACTIVE → HIDDEN → DELETED
```

### Legal Transitions

| From | To | Condition | Who |
|------|----|------------|-----|
| ACTIVE | HIDDEN | Content violation | Admin |
| HIDDEN | ACTIVE | Violation cleared | Admin |
| ACTIVE | DELETED | User deletes or hard violation | User/Admin |
| DELETED | ACTIVE | Undeleted (if user deletion) | Admin |

### State Rules

```dart
// ACTIVE
isVisible = true
canEdit = (author || within 5 minutes of creation)
canDelete = author

// HIDDEN
isVisible = false
canEdit = false
canDelete = admin only

// DELETED
isDeleted = true
isVisible = false
canEdit = false
canDelete = false
```

---

## FOLLOW RELATIONSHIP STATE

### States

```
NONE → FOLLOWING → NONE
             ↓
          BLOCKED
```

### Legal Transitions

| From | To | Condition | Action |
|------|----|------------|--------|
| NONE | FOLLOWING | User follows | Follow |
| FOLLOWING | NONE | User unfollows | Unfollow |
| NONE | BLOCKED | User blocks | Block |
| BLOCKED | NONE | User unblocks | Unblock |
| FOLLOWING | BLOCKED | Block takes precedence | Block |

### State Rules

```dart
// NONE
following = false
blocked = false
canFollow = true
canBlock = true

// FOLLOWING
following = true
blocked = false
canFollow = false
canUnfollow = true
canBlock = true

// BLOCKED
following = false
blocked = true
canFollow = false
canUnfollow = false
canBlock = false
canUnblock = true
```

---

## NOTIFICATION STATE MACHINE

### States

```
PENDING → SENT → DELIVERED → READ
         ↓       FAILED
       CANCELLED
```

### Legal Transitions

| From | To | Condition |
|------|----|------------|
| PENDING | SENT | Push service accepts |
| SENT | DELIVERED | Device receives |
| DELIVERED | READ | User opens app |
| SENT | FAILED | Delivery failed |
| PENDING | CANCELLED | User disabled notifications |

### State Rules

```dart
// PENDING
created = true
queued = true

// SENT
pushed = true
waitingForDelivery = true

// DELIVERED
delivered = true
waitingForRead = true

// READ
read = true
readAt = timestamp
```

---

## VALIDATION RULES

### By State

| State | Required Fields Must Be Valid |
|-------|------------------------------|
| AUTHENTICATED | access_token valid |
| PROFILE_INCOMPLETE | DOB or location must be null |
| PUBLISHED (event) | All required fields complete |
| ACTIVE (ticket) | QR code generated, not expired |
| SUCCESS (order) | Tickets issued |

### State Validation

```dart
// Cannot purchase ticket if profile incomplete
canBuyTicket = (user.state == AUTHENTICATED) &&
                (event.state == PUBLISHED) &&
                (now < event.startDate)

// Cannot check-in if ticket not active
canCheckIn = (ticket.state == ACTIVE) &&
             (event.state == STARTED) &&
             (now >= event.startDate) &&
             (now <= event.endDate)

// Cannot register if event full or not in PUBLISHED state
canRegister = (event.state == PUBLISHED) &&
               (now < event.startDate) &&
               (event.attendeesCount < event.capacity)
```

---

## STATE TRANSITION LOGS

### What to Log

Every state transition MUST be logged:

```json
{
  "entity_type": "ticket",
  "entity_id": "ticket_123",
  "from_state": "ACTIVE",
  "to_state": "USED",
  "trigger": "checkin",
  "triggered_by": "user_456",
  "timestamp": "2025-01-28T10:00:00Z"
}
```

### Required Logs

| Entity | Transitions to Log |
|--------|-------------------|
| User | LOGIN, LOGOUT, PROFILE_COMPLETE |
| Event | PUBLISH, START, END, CANCEL |
| Ticket | ACTIVATE, USE, EXPIRE, REFUND |
| Order | PENDING, PROCESSING, SUCCESS, FAIL |
| Post | PUBLISH, HIDE, DELETE |

---

## IMPLEMENTATION

### Backend (Go)

```go
// pkg/statemachine/ticket.go
type TicketState string

const (
    TicketReserved TicketState = "RESERVED"
    TicketActive   TicketState = "ACTIVE"
    TicketUsed     TicketState = "USED"
    TicketExpired  TicketState = "EXPIRED"
)

func (s TicketState) CanTransitionTo(newState TicketState) bool {
    // Define legal transitions
    // Note: No refund state in V1
}
```

### Frontend (Flutter)

```dart
// lib/domain/entities/ticket_state.dart
enum TicketState {
  reserved,
  active,
  used,
  expired,
}

class Ticket {
  final TicketState state;

  bool get canUse => state == TicketState.active;
  // Note: No canRefund property - refund not supported in V1
}
```

---

## REMEMBER

> **"State machines are not about complexity. They're about CLARITY."**

These state machines define the **legal** behavior of the system. Both frontend and backend MUST follow them.

**Illegal transitions = Bugs**. If you find code that violates these, it's a bug.

---

**LAST UPDATED**: 2025-01-28
**APPROVED BY**: Project Owner
**PURPOSE**: Define entity states and legal transitions
