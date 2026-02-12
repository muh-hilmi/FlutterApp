# 07. HOST EVENT MANAGEMENT

**User Flow**: Event creators can manage events they've created.

---

## FLOW OVERVIEW

```
Profile (Own)
    │
    ├─→ [View "Events Hosted" Section]
    │       │
    │       └─→ Tap "Manage Events" Button
    │               │
    │               ▼
    │        ┌───────────────┐
    │        │  My Events    │
    │        │   Screen      │
    │        └───────┬───────┘
    │                │
    │     ┌──────────┼──────────┐
    │     │          │          │
    │  [Event]   [Event]   [Event]
    │     │          │          │
    │     └────┬─────┴────┬─────┘
    │          │          │
    │    ┌─────┴─────┐  ┌─┴────────────┐
    │    │           │  │              │
    │  [EDIT]    [DELETE]        [CHECK-IN]
    │    │           │              │
    │    ▼           ▼              ▼
    │  Edit Event  Confirm    Participant
    │   Screen    Delete     List Screen
    │    │           │              │
    │    │      ┌────┴────┐         │
    │    │      │         │         ▼
    │    │    Cancel   Delete    QR Scan
    │    │              │       Screen
    │    └──────────────┴─────────┘
    │
    └─→ Return to Profile
```

---

## SCREEN 1: MY EVENTS

**Route**: `/my-events` (or accessed from Profile → Events Hosted section)

**Purpose**: User can see all events they've created and take actions.

### UI Layout

```
┌─────────────────────────────────────┐
│ ← My Events                        │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🎉 Weekend Meetup             │ │
│  │ 📅 30 Jan 2025 • 19:00       │ │
│  │ 👥 5/50 attendees            │ │
│  │ 📍 Central Park              │ │
│  │                               │ │
│  │ [Edit] [Delete] [Check-in]   │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🏸 Sports Tournament          │ │
│  │ 📅 05 Feb 2025 • 08:00       │ │
│  │ 👥 0/100 attendees           │ │
│  │ 📍 Sports Complex            │ │
│  │                               │ │
│  │ [Edit] [Delete] [Check-in]   │ │
│  └───────────────────────────────┘ │
│                                     │
│  [Empty State if no events]        │
│                                     │
└─────────────────────────────────────┘
```

### Key Elements

| Element | Type | Key |
|---------|------|-----|
| Back button | IconButton | `my_events_back_button` |
| Event card (per event) | Container | `event_card_{index}` |
| Event title | Text | `event_title_{index}` |
| Edit button | IconButton | `edit_button_{index}` |
| Delete button | IconButton | `delete_button_{index}` |
| Check-in button | IconButton | `checkin_button_{index}` |
| Empty state | Container | `empty_state_container` |
| FAB create new | FloatingActionButton | `create_event_fab` |

### Empty State

When user has no events:
```
┌─────────────────────────────────────┐
│         📭                          │
│                                     │
│     Belum ada event                 │
│                                     │
│  Mulai buat event seru sekarang!   │
│                                     │
│     [Buat Event Baru]              │
└─────────────────────────────────────┘
```

---

## SCREEN 2: EDIT EVENT

**Route**: `/event/:id/edit`

**Purpose**: User can edit event details **only if no attendees yet**.

### Business Rules

✅ **CAN edit if**:
- Event status = `upcoming`
- `attendees_count` = 0
- Event hasn't started yet

❌ **CANNOT edit if**:
- Has attendees (`attendees_count` > 0)
- Event already started/ended
- Event status = `cancelled`

### UI Layout

Same as Create Event screen, but pre-filled with existing data.

### Key Elements

| Element | Type | Key |
|---------|------|-----|
| Save button | ElevatedButton | `save_event_button` |
| Cancel button | TextButton | `cancel_edit_button` |
| Form fields | Various | Same as create event |

### Error States

If user tries to edit event with attendees:
```
┌─────────────────────────────────────┐
│         ⚠️                          │
│                                     │
│  Tidak bisa edit event              │
│                                     │
│  Event ini sudah memiliki peserta.  │
│  Silakan hubungi admin jika         │
│  perlu perubahan mendesak.         │
│                                     │
│          [OK]                       │
└─────────────────────────────────────┘
```

---

## SCREEN 3: CONFIRM DELETE

**Purpose**: Confirmation dialog before deleting event.

### Business Rules

✅ **CAN delete if**:
- Event status = `upcoming`
- `attendees_count` = 0

❌ **CANNOT delete if**:
- Has attendees
- Event already started

### UI Layout (Dialog)

```
┌─────────────────────────────────────┐
│         Hapus Event?                │
├─────────────────────────────────────┤
│                                     │
│  Event "{Event Title}" akan         │
│  dihapus secara permanen.           │
│                                     │
│  Tindakan ini tidak dapat dibatalkan│
│                                     │
│         [Batal]  [Hapus]           │
└─────────────────────────────────────┘
```

### Error Dialog (if cannot delete)

```
┌─────────────────────────────────────┐
│         ⚠️                          │
│                                     │
│  Tidak bisa menghapus event         │
│                                     │
│  {Reason: sudah ada peserta /        │
│   event sudah dimulai}              │
│                                     │
│          [OK]                       │
└─────────────────────────────────────┘
```

---

## SCREEN 4: PARTICIPANT LIST (Check-in)

**Route**: `/event/:id/participants`

**Purpose**: Host can see who bought tickets and check them in.

### UI Layout

```
┌─────────────────────────────────────┐
│ ← Peserta Event (0/50 checked-in)  │
├─────────────────────────────────────┤
│                                     │
│  🔍 Search peserta...               │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 👤 Budi Santoso               │ │
│  │ 🎫 Regular Ticket            │ │
│  │ ✅ Checked in at 19:15        │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 👤 Siti Rahma                 │ │
│  │ 🎫 Regular Ticket            │ │
│  │ ⏳ Belum check-in             │ │
│  │                               │ │
│  │     [Scan QR]  [Check-in]     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 👤 Ahmad Dani                 │ │
│  │ 🎫 VIP Ticket                 │ │
│  │ ⏳ Belum check-in             │ │
│  │                               │ │
│  │     [Scan QR]  [Check-in]     │ │
│  └───────────────────────────────┘ │
│                                     │
│  [Empty State if no attendees]     │
│                                     │
└─────────────────────────────────────┘
```

### Key Elements

| Element | Type | Key |
|---------|------|-----|
| Search bar | TextField | `participant_search_field` |
| Participant card | Container | `participant_card_{index}` |
| Check-in button | IconButton | `checkin_button_{index}` |
| Scan QR button | IconButton | `scan_qr_button_{index}` |
| Checked-in badge | Badge | `checked_in_badge_{index}` |

---

## SCREEN 5: QR SCAN (Check-in)

**Route**: `/event/:id/scan`

**Purpose**: Scan participant QR code to check them in.

### UI Layout

```
┌─────────────────────────────────────┐
│                                     │
│         [Camera Viewfinder]         │
│                                     │
│     Arahkan ke QR code peserta      │
│                                     │
├─────────────────────────────────────┤
│  📋 Manual Check-in                 │
└─────────────────────────────────────┘
```

### On Scan Success

```
┌─────────────────────────────────────┐
│         ✅ Check-in Berhasil!       │
├─────────────────────────────────────┤
│                                     │
│  👤 Budi Santoso                   │
│  🎫 Regular Ticket                 │
│  🕐 Checked in at 19:15            │
│                                     │
│          [OK]  [Scan Next]         │
└─────────────────────────────────────┘
```

### Already Checked-in

```
┌─────────────────────────────────────┐
│         ℹ️ Sudah Check-in          │
├─────────────────────────────────────┤
│                                     │
│  Budi Santoso sudah check-in        │
│  pada pukul 19:15                  │
│                                     │
│              [OK]                   │
└─────────────────────────────────────┘
```

### Invalid QR

```
┌─────────────────────────────────────┐
│         ❌ QR Tidak Valid           │
├─────────────────────────────────────┤
│                                     │
│  QR code ini tidak terdaftar        │
│  untuk event ini                    │
│                                     │
│              [OK]                   │
└─────────────────────────────────────┘
```

---

## NAVIGATION

### From Profile

```
Profile (Own)
    → Tap "Manage Events" button
    → My Events Screen
```

### From My Events

```
My Events
    → Tap [Edit] on event → Edit Event Screen
    → Tap [Delete] on event → Confirm Delete Dialog
    → Tap [Check-in] on event → Participant List Screen
```

### From Participant List

```
Participant List
    → Tap [Scan QR] on participant → QR Scan Screen
    → Tap [Check-in] button → Manual check-in
```

---

## API CONTRACTS

See `BLUEPRINT/03_api_contracts.md` for:
- GET `/api/v1/users/me/events` - Get user's hosted events
- PUT `/api/v1/events/:id` - Update event
- DELETE `/api/v1/events/:id` - Delete event
- GET `/api/v1/events/:id/attendees` - Get attendee list
- POST `/api/v1/events/:id/check-in` - Check-in attendee

---

## TEST KEYS

| Screen | Test Key Required |
|--------|-------------------|
| My Events | `my_events_screen`, `event_card_0`, `edit_button_0`, `delete_button_0`, `checkin_button_0` |
| Edit Event | `edit_event_screen`, `save_event_button`, `cancel_edit_button` |
| Confirm Delete | `delete_confirm_dialog`, `confirm_delete_button`, `cancel_delete_button` |
| Participant List | `participant_list_screen`, `participant_search_field`, `checkin_button_0` |
| QR Scan | `qr_scan_screen`, `camera_viewfinder` |

---

**LAST UPDATED**: 2025-01-29
**STATUS**: ✅ Ready for Implementation
