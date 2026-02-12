# BLUEPRINT CONSISTENCY AUDIT REPORT

**Date**: 2025-01-28
**Auditor**: Spec Guardian & Consistency Auditor
**Scope**: Full blueprint consistency audit against 11_state_machines.md (SSOT) and 10_non_goals.md

---

## 🔴 CRITICAL VIOLATIONS (MUST FIX)

### 1. API Contracts - Missing State Preconditions

**File**: `03_api_contracts.md`
**Baris**: 324-345 (Purchase Ticket Endpoint)

**Masalah**:
```json
POST /api/v1/tickets/purchase
{
  "event_id": "event_123",
  "ticket_type_id": "ticket_123",
  "quantity": 2
}
```

TIDAK ada precondition check untuk:
- `event.state == PUBLISHED`
- `event.state != CANCELLED`
- `user.state == AUTHENTICATED`
- `now < event.startDate`

**Kenapa Melanggar SSOT**:
State machine `11_state_machines.md` baris 89-127 mendefinisikan event state, tapi API tidak enforce ini.

**Perbaikan yang Disarankan**:
Tambahkan section "Preconditions" dan "Postconditions":
```markdown
### Purchase Ticket
POST /api/v1/tickets/purchase

**Preconditions**:
- `event.state == PUBLISHED`
- `user.state == AUTHENTICATED`
- `now < event.startDate`
- `event.attendeesCount < event.capacity`

**Postconditions**:
- Creates order with `order.state = PENDING`
- On payment success: `order.state = SUCCESS` → Creates tickets with `ticket.state = ACTIVE`
```

---

### 2. API Contracts - Check-in Without State Validation

**File**: `03_api_contracts.md`
**Baris**: 384-410 (Check-in Endpoint)

**Masalah**:
```json
POST /api/v1/tickets/{ticket_id}/checkin
```

TIDAK ada check untuk:
- `ticket.state == ACTIVE`
- `ticket.state != USED`
- `event.state == STARTED`
- Time window validation

**Kenapa Melanggar SSOT**:
State machine `11_state_machines.md` baris 197-205 defines QR rules by state, tapi API tidak enforce.

**Perbaikan yang Disarankan**:
```markdown
### Check-in
POST /api/v1/tickets/{ticket_id}/checkin

**Preconditions**:
- `ticket.state == ACTIVE`
- `event.state == STARTED`
- `now >= event.startDate`
- `now <= event.endDate`
- `!ticket.isUsed`

**Postconditions**:
- `ticket.state transitions from ACTIVE → USED`
- Sets `ticket.checkedInAt = now`
- Returns error if already USED

**State Transition**: ACTIVE → USED (terminal)
```

---

### 3. Data Models - Redundant Boolean Field

**File**: `04_data_models.md`
**Baris**: 147

**Masalah**:
```dart
class Ticket {
  final TicketStatus status;  // enum
  final bool checkedIn;       // REDUNDANT!
}
```

`checkedIn` boolean is redundant dengan `status`. Harusnya:
- `isUsed = (status == TicketStatus.used)`
- `canCheckIn = (status == TicketStatus.active)`

**Kenapa Melanggar SSOT**:
State machine `11_state_machines.md` defines state sebagai single source of truth. Redundant fields create inconsistency risk.

**Perbaikan yang Disarankan**:
```dart
class Ticket {
  final TicketStatus state;  // Was: status
  final DateTime? usedAt;    // Was: checkedInAt

  // Computed properties (NOT stored)
  bool get isUsed => state == TicketStatus.used;
  bool get canCheckIn => state == TicketStatus.active;
}
```

---

### 4. Data Models - Wrong Vocabulary

**File**: `03_api_contracts.md`, `04_data_models.md`
**Baris**: 03_api_contracts.md:373, 04_data_models.md:146

**Masalah**:
```json
"status": "active"  // ❌ WRONG
"checked_in": false // ❌ REDUNDANT
```

Harusnya:
```json
"state": "ACTIVE"   // ✅ CORRECT
// "checked_in" removed, derived from state
```

**Kenapa Melanggar SSOT**:
Coding standards `08_coding_standards.md` dan consistency pass sudah establish: use `state` bukan `status`.

**Perbaikan yang Disarankan**:
Update ALL API responses:
```json
{
  "id": "ticket_123",
  "qr_code": "QR_DATA_STRING",
  "state": "ACTIVE",  // ✅ Uppercase, matches enum
  "purchased_at": "2025-01-28T10:00:00Z"
  // "checked_in" removed - client derives from state
}
```

---

### 5. User Flow - Missing State Machine References

**File**: `02_user_flows/flow_03_event.md`
**Baris**: 47-53, 243-251

**Masalah**:
Button state table TIDAK mention state machine:
```markdown
| State | Button Text |
|-------|-------------|
| Available, paid | [BELI TIKET] |
| Already registered | [TERDAFTAR] |
```

Apa itu "Available"? "Already registered"? Ini UI state, bukan entity state!

**Kenapa Melanggar SSOT**:
Tidak jelas mapping dari UI state ke entity state dari `11_state_machines.md`.

**Perbaikan yang Disarankan**:
```markdown
| Event State | Condition | Button Text | Action |
|-------------|-----------|-------------|--------|
| PUBLISHED | free, (now < startDate) | [DAFTAR] | → /event/:id/tickets |
| PUBLISHED | paid, (now < startDate) | [BELI TIKET] | → /event/:id/tickets |
| STARTED | - | [SEDANG BERLANGSUNG] | Disabled (live indicator) |
| ENDED | - | [SELESAI] | Disabled |
| CANCELLED | - | [DIBATALKAN] | Disabled |
```

---

### 6. Settings Screen - Non-V1 Features

**File**: `02_user_flows/flow_04_profile.md`
**Baris**: 140, 154

**Masalah**:
```markdown
| Password | [Change password] | [>] |
| Delete Account | [>] | |
```

**Kenapa Melanggar SSOT**:
`10_non_goals.md` baris 15: "Email/password login | ❌ NOT V1"
Tidak ada "Delete Account" atau "Change Password" di V1 scope.

**Perbaikan yang Disarankan**:
Hapus kedua row ini:
```markdown
├─────────────────────────────────────┤
│ PREFERENCES                         │
│   Notifications   [On]         [>] │
│   Language        [Indonesia]   [>] │
├─────────────────────────────────────┤
│ SUPPORT                             │
│   Help Center                  [>] │
│   Terms of Service             [>] │
│   Privacy Policy               [>] │
├─────────────────────────────────────┤
│ DANGER ZONE                         │
│   Log Out                     [>] │
└─────────────────────────────────────┘
```

---

## 🟠 INCONSISTENCIES

### 7. API Response - Missing State Field

**File**: `03_api_contracts.md`
**Baris**: 262-306 (Get Event Details)

**Masalah**:
Event response TIDAK include `state` field:
```json
{
  "id": "event_123",
  "title": "Music Festival 2025",
  // ❌ No "state" field!
}
```

Frontend perlu tahu `event.state` untuk:
- Show correct button (BUY vs LIVE vs ENDED)
- Filter lists correctly
- Show/hide in feeds

**Perbaikan yang Disarankan**:
```json
{
  "id": "event_123",
  "state": "PUBLISHED",  // ✅ Add this
  "title": "Music Festival 2025",
  // ... other fields
}
```

---

### 8. Business Rules - Location Required Confusion

**File**: `04_data_models.md`
**Baris**: 374

**Masalah**:
```markdown
| User.location | No | Required for V1 |
```

Tapi di `05_business_rules.md` baris 39-45:
```markdown
| Location | No* | null (Jakarta if denied) |
\* Required for recommendations, but can skip.
```

Kontradiksi: Required vs can skip?

**Perbaikan yang Disarankan**:
Update `04_data_models.md` baris 374:
```markdown
| User.location | No | Optional but recommended (Jakarta default if denied) |
```

---

### 9. User Flow - Error States Without State Context

**File**: `02_user_flows/flow_03_event.md`
**Baris**: 213-218

**Masalah**:
```markdown
| Error | Message |
|-------|---------|
| QR expired | "Tiket sudah kadaluarsa" |
| Already checked | "Kamu sudah check-in" |
```

TIDAK mention bahwa ini seharusnya dicek via `ticket.state`:
- `QR expired` = `ticket.state == EXPIRED`
- `Already checked` = `ticket.state == USED`

**Perbaikan yang Disarankan**:
```markdown
| Error | Message | State Check |
|-------|---------|-------------|
| Ticket invalid | "Tiket tidak valid" | `ticket.state != ACTIVE` |
| Already checked | "Kamu sudah check-in" | `ticket.state == USED` |
| Event not started | "Check-in dibuka pada {start}" | `event.state != STARTED` |
| Event ended | "Tiket sudah kadaluarsa" | `now > event.endDate` |
```

---

## 🟡 REDUNDANCIES / CLEANUP

### 10. API Response - Inconsistent Field Naming

**File**: `03_api_contracts.md`
**Baris**: 96-113 (Get Current User)

**Masalah**:
```json
{
  "date_of_birth": "1990-01-15",  // snake_case
  "interests": ["Music", "Sports"] // OK
}
```

Tapi di `04_data_models.md` baris 19:
```dart
final DateTime? dateOfBirth;  // camelCase
```

**Perbaikan yang Disarankan**:
API contract should note that JSON uses snake_case but maps to camelCase Dart fields. Atau, gunakan camelCase consistently di API (Flutter convention).

---

### 11. User Flow - Business Rules Duplication

**File**: `02_user_flows/flow_03_event.md`
**Baris**: 243-251

**Masalah**:
Flow file mendefinisikan business rules:
```markdown
| Rule | Value |
|------|-------|
| Max tickets per transaction | 10 |
```

Tapi ini SAMA dengan `05_business_rules.md` baris 236-241.

**Perbaikan yang Disarankan**:
Hapus duplikasi, ganti dengan reference:
```markdown
## BUSINESS RULES

See: [`05_business_rules.md`](../05_business_rules.md#tickets)

Key rules for this flow:
- Max tickets: 10 per transaction
- Payment timeout: 15 minutes
- QR valid until: Event end time

For complete rules, see business rules document.
```

---

## 🟢 OK / CONFIRMED CLEAN

### 12. State Machine - Ticket States ✅

**File**: `04_data_models.md`
**Baris**: 152-157

Setelah refund removal:
```dart
enum TicketStatus {
  reserved,
  active,
  used,
  expired,
}
```

✅ PERFECTLY matches `11_state_machines.md` baris 136-142.

---

### 13. New User Flow ✅

**File**: `02_user_flows/flow_01_new_user.md`

Semua state transitions sudah benar:
- No token → `/login`
- New user → `/complete-profile` → `/home`
- Existing user → `/home`

✅ No violations found.

---

### 14. Event State Machine Reference ✅

**File**: `05_business_rules.md`
**Baris**: 113-145

Setelah consistency pass kedua, semua event state rules sudah reference `11_state_machines.md`:
```dart
// From state machine 11_state_machines.md#event-state-machine
// PUBLISHED state
canRegister = true  // Time-limited: now < event.startDate
```

✅ Perfect alignment.

---

### 15. Refund Removal ✅

**Files**: `11_state_machines.md`, `05_business_rules.md`, `04_data_models.md`, `README.md`

Setelah consistency pass kedua:
- ❌ No REFUNDED state
- ❌ No canRefund properties
- ❌ No refund transitions
- ✅ Only explanatory notes: "No refund mechanism in V1"

✅ 100% clean, 0 surface area for refund.

---

## 📊 SUMMARY

### Critical Violations: 6
1. API missing state preconditions
2. API check-in without state validation
3. Data models redundant boolean field
4. Wrong vocabulary (status vs state)
5. User flow missing state machine refs
6. Settings screen non-V1 features

### Inconsistencies: 3
7. API response missing state field
8. Location required confusion
9. Error states without state context

### Redundancies: 2
10. API field naming inconsistency
11. Business rules duplication

### Clean/OK: 4
12-15. State machine, new user flow, event rules, refund removal

---

## 🛠️ REQUIRED ACTIONS

### Priority 1 (MUST FIX BEFORE IMPLEMENTATION):

1. **Update `03_api_contracts.md`**:
   - Add Preconditions/Postconditions for ALL state-changing endpoints
   - Change `"status"` → `"state"` everywhere
   - Remove `"checked_in"` from responses
   - Add `"state": "PUBLISHED"` to event response

2. **Update `04_data_models.md`**:
   - Change `TicketStatus status` → `TicketStatus state`
   - Remove `bool checkedIn`
   - Add computed properties: `isUsed`, `canCheckIn`
   - Update location requirement clarification

3. **Update `02_user_flows/flow_03_event.md`**:
   - Add state machine references to button table
   - Add state checks to error states
   - Reference `05_business_rules.md` instead of duplicating

4. **Update `02_user_flows/flow_04_profile.md`**:
   - Remove "Password" field from settings
   - Remove "Delete Account" from settings
   - Keep only V1 features

### Priority 2 (SHOULD FIX):

5. Standardize API field naming (snake_case vs camelCase)

6. Add state fields to ALL API responses (User, Post, etc.)

---

## ✅ SUCCESS CRITERIA

After fixes, blueprint must:

✅ **Tidak ada satupun cara di sistem untuk**:
- Mengubah terminal state (USED, EXPIRED, SUCCESS)
- Melakukan refund
- Membypass state machine
- Mengakses fitur non-V1

✅ **Semua file bawah follow otoritas hierarki**:
- 10_non_goals.md > 11_state_machines.md > 05_business_rules.md > API/flows/models

✅ **State machine adalah SSOT**:
- Semua state references use exact names from 11_state_machines.md
- Tidak ada redundant state fields
- Tidak ada "status" vs "state" inconsistency

---

**STATUS**: 🔴 AUDIT COMPLETE - 6 CRITICAL ISSUES FOUND
**NEXT STEP**: Execute Priority 1 fixes
**TARGET**: Blueprint locked, consistent, and ready for implementation

---

**LAST UPDATED**: 2025-01-28
**AUDITED BY**: Spec Guardian & Consistency Auditor
**APPROVAL**: Pending Project Owner review
