# FLOW 3: Event & Ticket Purchase

**Journey**: Browse event → Buy ticket → Get QR

---

## EVENT DETAIL (`/event/:id`)

### Layout

```
┌─────────────────────────────────────┐
│ [←] Event Title                    │
├─────────────────────────────────────┤
│ EVENT PHOTO (hero)                  │
├─────────────────────────────────────┤
│ 📅 Date & Time                      │
│ 📍 Location (tap → maps)           │
│ 👥 123 attending                    │
│ 💰 Rp 150.000                      │
├─────────────────────────────────────┤
│ DESCRIPTION (expandable)             │
├─────────────────────────────────────┤
│ HOST: [Avatar] [Name] [Follow]      │
├─────────────────────────────────────┤
│ Q&A SECTION                          │
│ - Question 1                         │
│ - [Ask Question]                     │
├─────────────────────────────────────┤
│ [FIXED] [BELI TIKET]                │
└─────────────────────────────────────┘
```

### Actions

| Element | Action |
|---------|--------|
| [←] Back | Return to previous |
| Location | Open Google Maps |
| Host | Go to `/profile/:hostId` |
| [Follow] | Toggle follow state |
| Q&A | Open question dialog |
| [BELI TIKET] | → `/event/:id/tickets` |

### Button States

Based on state machine [`11_state_machines.md`](../11_state_machines.md#event-state-machine):

| Event State | Condition | Button Text | Action |
|-------------|-----------|-------------|--------|
| PUBLISHED | free, (now < startDate) | [DAFTAR] | → /event/:id/tickets |
| PUBLISHED | paid, (now < startDate) | [BELI TIKET] | → /event/:id/tickets |
| PUBLISHED | user has ACTIVE ticket | [LIHAT TIKET] | → /my-tickets |
| STARTED | - | [SEDANG BERLANGSUNG] | Disabled (live indicator) |
| ENDED | - | [SELESAI] | Disabled |
| CANCELLED | - | [DIBATALKAN] | Disabled |
| PUBLISHED | full | [HABIS] | Disabled |

### Price Display

- Free: "Gratis"
- Single: "Rp 150.000"
- Range: "Mulai dari Rp 50.000"

**Test Keys**: `event_detail_screen`, `buy_button`, `back_button`

---

## TICKET SELECTION (`/event/:id/tickets`)

### Layout

```
┌─────────────────────────────────────┐
│ [←] Tiket: Event Name              │
├─────────────────────────────────────┤
│ Ticket Types:                       │
│ ○ Regular - Rp 150.000             │
│ ○ VIP - Rp 300.000                 │
│ ⊗ Early Bird - Rp 100.000 (sold)   │
├─────────────────────────────────────┤
│ Quantity: [ - ] 1 [ + ]            │
│ Total: Rp 150.000                  │
├─────────────────────────────────────┤
│ [CANCEL]        [LANJUT BAYAR]      │
└─────────────────────────────────────┘
```

### Actions

- Tap ticket type → Select (radio button)
- Tap [-]/[+] → Change quantity (1-10)
- Tap [CANCEL] → Back to event detail
- Tap [LANJUT BAYAR] → Open Midtrans

### Validation

| Rule | Message |
|------|---------|
| At least 1 ticket | "Pilih minimal 1 tiket" |
| Max 10 tickets | "Maksimal 10 tiket" |

**Test Keys**: `ticket_selection_screen`, `ticket_type_{$type}`, `quantity_selector`

---

## MIDTRANS PAYMENT

### Flow

1. Open Midtrans SDK/webview
2. User selects payment method
3. Completes payment

### Results

| Result | Action |
|--------|--------|
| Success | Show success dialog → `/my-tickets` |
| Failed | Show error → Back to ticket selection |
| Pending | Show "Payment in progress" → `/my-tickets` |
| Cancelled | Back to ticket selection |

---

## TICKET CONFIRMATION

### Layout (After Success)

```
┌─────────────────────────────────────┐
│     ✅ Pembayaran Berhasil!         │
│                                     │
│ Tiketmu sudah siap. Simpan QR.      │
│                                     │
│     [📲 QR CODE DISPLAY]            │
│                                     │
│ Event: Music Festival 2025          │
│ Date: 15 Feb 2025, 19:00            │
│ Ticket: Regular x1                  │
│                                     │
│ [LIHAT TIKET SAYA]    [SHARE]       │
└─────────────────────────────────────┘
```

### Actions

- [LIHAT TIKET SAYA] → `/my-tickets`
- [SHARE] → Share ticket image

---

## MY TICKETS (`/my-tickets`)

### Layout

```
┌─────────────────────────────────────┐
│ [←] Tiket Saya                     │
├─────────────────────────────────────┤
│ TABS: [Upcoming] [Past]             │
├─────────────────────────────────────┤
│ TICKET CARDS:                       │
│ ┌─────────────────────────────────┐ │
│ │ [Event Photo]                   │ │
│ │ Event Name                      │ │
│ │ Date & Time                     │ │
│ │ Location                        │ │
│ │ [📲 QR] [VIEW DETAILS]          │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Actions

- Tap [📲 QR] → Full screen QR
- Tap [VIEW DETAILS] → `/event/:id`

### Empty States

| Tab | Empty Message |
|-----|---------------|
| Upcoming | "Belum ada tiket. Cari event yuk!" |
| Past | "Belum ada riwayat event" |

**Test Keys**: `my_tickets_screen`, `ticket_card_{$id}`, `qr_button`

---

## CHECK-IN QR

### Layout

```
┌─────────────────────────────────────┐
│ [←] Check-in                       │
│                                     │
│      [📲 FULL SCREEN QR CODE]       │
│                                     │
│ Scan QR ini di lokasi event         │
│                                     │
│ Event: Music Festival               │
│ Location: GBK Arena                 │
│                                     │
│ Status: ✅ Belum check-in           │
└─────────────────────────────────────┘
```

### After Check-in

- Status: "✅ Sudah check-in pada 19:30"
- Confetti animation
- Message: "Selamat menikmati event!"

### Error States

Based on state machine [`11_state_machines.md`](../11_state_machines.md#ticket-state-machine):

| Error | Message | State Check |
|-------|---------|-------------|
| Ticket invalid | "Tiket tidak valid" | `ticket.state != ACTIVE` |
| Already checked in | "Kamu sudah check-in" | `ticket.state == USED` |
| Event not started | "Check-in dibuka pada {start}" | `event.state != STARTED` |
| Event ended | "Tiket sudah kadaluarsa" | `now > event.endDate` |
| Invalid QR | "QR code tidak valid" | QR validation failed |
| Network error | "Gagal verifikasi. Coba lagi" | Connection error |

**Test Keys**: `qr_checkin_screen`, `qr_display`, `checkin_status`

---

## FLOW DIAGRAM

```
Event Detail → Buy Ticket → Ticket Selection
                                   ↓
                            Midtrans Payment
                                   ↓
                          ┌───────┴───────┐
                          ↓               ↓
                       Success         Fail/Cancel
                          ↓               ↓
                   Ticket Conf.    Back to Selection
                          ↓
                    My Tickets → QR → Check-in
```

---

## BUSINESS RULES

See: [`05_business_rules.md`](../05_business_rules.md#tickets)

**Key rules for this flow**:
- Max tickets: 10 per transaction
- Min tickets: 1 per transaction
- Payment timeout: 15 minutes
- QR valid until: Event end time
- Can check-in from: Event start time
- Can check-in until: Event end time

**For complete rules**, state transitions, and validation logic, see business rules document.

---

## IMPLEMENTATION

**Files**:
- `lib/presentation/pages/event/event_detail_screen.dart`
- `lib/presentation/pages/ticket/ticket_selection_screen.dart`
- `lib/presentation/pages/ticket/my_tickets_screen.dart`

**BLoCs**:
- `lib/presentation/bloc/event/event_bloc.dart`
- `lib/presentation/bloc/ticket/ticket_bloc.dart`
- `lib/presentation/bloc/payment/payment_bloc.dart`
