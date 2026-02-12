# V1 Refund Removal Summary

**Date**: 2025-01-28
**Authority**: `10_non_goals.md` line 65 - "Refund system | ❌ NOT V1"
**Decision**: Remove ALL refund concepts from V1 state machines and business rules

---

## 🎯 OBJECTIVE

Eliminate refund mechanism from V1 to comply with `10_non_goals.md`. All purchases are final in V1.

---

## 📋 FILES MODIFIED

### 1. `11_state_machines.md`

**State Changes**:
- ❌ Removed: `REFUNDED` state from ticket state machine
- ✅ States: `RESERVED → ACTIVE → USED → EXPIRED` (terminal: USED, EXPIRED)

**Transition Changes**:
- ❌ Removed: `RESERVED → REFUNDED` (payment timeout/cancelled)
- ❌ Removed: `ACTIVE → REFUNDED` (refund approved)
- ❌ Removed: `REFUNDED → ACTIVE` (refund reversed)
- ❌ Removed: `SUCCESS → REFUNDED` (order refund)
- ❌ Removed: `REFUNDED → SUCCESS` (refund reversal)

**Property Changes**:
- ❌ Removed: `canRefund` property from all states
- ❌ Removed: `isRefunded` property
- ✅ Added: `notifyAttendees = true` for CANCELLED events (not refund, just notification)

**Implementation Changes**:
- Go: Removed `TicketRefunded` constant
- Dart: Removed `refunded` enum value
- Dart: Removed `canRefund` getter

---

### 2. `05_business_rules.md`

**Policy Statement**:
```
⚠️ V1 Refund Policy: All purchases are final. No refund mechanism in V1
(see 10_non_goals.md). No exceptions, no admin overrides, no manual refunds.
```

**Section Changes**:
- ❌ Removed: `canRefund = true` from all ticket states
- ❌ Removed: REFUNDED row from QR Code Rules table
- ❌ Removed: `canRefund = true` from SUCCESS order state
- ❌ Removed: Entire "Refund (V1 - Limited)" section
- ✅ Added: Clear policy statement "All purchases are final"

**UI Changes**:
- Changed: CANCELLED event button text from "show refund status" to "event cancelled by organizer"

---

### 3. `04_data_models.md`

**Enum Changes**:
- ❌ Removed: `refunded` from TicketStatus enum
- ✅ States: `reserved, active, used, expired`

**Added Note**:
```
Note: No `refunded` status in V1. All purchases are final (see 10_non_goals.md).
```

---

### 4. `README.md`

**State Machine Overview**:
- ❌ Removed: `→ REFUNDED` from Ticket state machine visualization
- ✅ Shows: `RESERVED → ACTIVE → USED → EXPIRED`

---

## 🔄 CONCEPTUAL DIFF

### BEFORE (Inconsistent with 10_non_goals.md)

```
TICKET STATE MACHINE (OLD)
├── RESERVED
│   └── canRefund = true
├── ACTIVE
│   └── canRefund = true
├── USED
│   └── canRefund = false (terminal)
├── EXPIRED
│   └── canRefund = false (terminal)
└── REFUNDED ❌ (V1 scope violation)
    └── isRefunded = true

ORDER STATE MACHINE (OLD)
├── SUCCESS
│   └── canRefund = true (V2: manual only)
│   └── SUCCESS → REFUNDED (admin action) ❌
└── REFUNDED ❌ (V1 scope violation)

BUSINESS RULES (OLD)
├── "Refund system | ❌ NOT V1" (10_non_goals.md)
├── "V1 Refund Rules: Manual only (admin approval)" ❌
└── SUCCESS → REFUNDED transition exists ❌
```

**Problem**: State machine allowed refund (even "manual-only"), but `10_non_goals.md` said refund is NOT V1. This created an "admin escape hatch" that violated scope.

---

### AFTER (Aligned with 10_non_goals.md)

```
TICKET STATE MACHINE (NEW)
├── RESERVED (no canRefund property)
├── ACTIVE (no canRefund property)
├── USED (terminal, truly final)
└── EXPIRED (terminal, truly final)

ORDER STATE MACHINE (NEW)
└── SUCCESS (terminal, truly final)
    ❌ No SUCCESS → REFUNDED transition
    ❌ No canRefund property

BUSINESS RULES (NEW)
├── ⚠️ V1 Refund Policy: All purchases are final
├── No refund mechanism in V1 (see 10_non_goals.md)
├── No exceptions, no admin overrides, no manual refunds
└── USED, EXPIRED, SUCCESS are truly terminal states
```

**Solution**: Complete removal of refund concept from V1. If V2 needs refund, it will be a NEW state and NEW file, not an "admin override" in V1.

---

## ✅ VERIFICATION

### Refund Surface Area: 0 in V1

| Check | Result |
|-------|--------|
| REFUNDED state exists? | ❌ No |
| canRefund property exists? | ❌ No |
| SUCCESS → REFUNDED transition? | ❌ No |
| REFUNDED → ACTIVE transition? | ❌ No |
| Refund section in business rules? | ❌ No |
| Refund in data models? | ❌ No |
| Refund in README overview? | ❌ No |
| Admin refund override? | ❌ No |
| "Manual refund" loophole? | ❌ No |

**Remaining References** (all explanatory):
- Notes: "No refund mechanism in V1 (see 10_non_goals.md)"
- Notes: "All purchases are final"
- Notes: "No canRefund property - refund not supported in V1"

These are NOT functional refund logic - they explicitly REFUSE refund.

---

## 🔒 GOVERNANCE LOCK

**Hierarchy Established**:
```
10_non_goals.md (HIGHEST AUTHORITY)
    ↓
11_state_machines.md (must comply)
    ↓
05_business_rules.md (must comply)
    ↓
04_data_models.md (must comply)
```

**Rule**: If `10_non_goals.md` says "NOT V1", then:
1. State machine CANNOT have that state
2. Business rules CANNOT have "manual-only" workaround
3. NO "admin override" loophole
4. NO "operational flexibility" exception

**V2 Process**: If V2 wants refund, it must:
1. Add REFUNDED state to NEW state machine version (v2)
2. Update `10_non_goals.md` to move "Refund system" from "NOT V1" to "V2"
3. Add NEW file: `12_refund_state_machine_v2.md`
4. Clearly separate V1 (no refund) from V2 (with refund)

---

## 📊 IMPACT ANALYSIS

### What Changed
- **State Machine**: 5 states → 4 states (ticket), 1 less terminal (order)
- **Properties**: -2 properties (canRefund, isRefunded)
- **Transitions**: -4 transitions (all refund-related)
- **Code Examples**: Updated Go/Dart to remove REFUNDED

### What Stayed Same
- Event CANCELLED still exists (not refund, just cancellation)
- Notification system for cancelled events
- All other state transitions intact
- All other business rules intact

### Migration Path (V1 → V2)
When V2 adds refund:
1. Add `REFUNDED` state to ticket state machine
2. Add `SUCCESS → REFUNDED` to order state machine
3. Add `canRefund` properties back
4. Create NEW refund workflow (separate from V1)
5. Update `10_non_goals.md` to mark as V2 feature

---

**APPROVED BY**: Project Owner
**LAST UPDATED**: 2025-01-28
**PURPOSE**: Lock V1 specification - refund = 0 surface area
