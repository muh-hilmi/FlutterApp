# FLOW 4: Profile & Settings

**Journey**: View profile → Edit → Settings → Logout

---

## PROFILE SCREEN (`/profile`)

### Two Modes

#### Mode A: Own Profile (Default)

```
┌─────────────────────────────────────┐
│ [⋮]                                │
├─────────────────────────────────────┤
│         [AVATAR - 60px]             │
│                                     │
│         [USER NAME]                 │
│         [Location]                  │
│                                     │
│      [BIO - max 2 lines]            │
│                                     │
│ [Events:5] [Followers:120] [Following:80] │
│                                     │
│      [EDIT PROFIL]                  │
├─────────────────────────────────────┤
│ TABS: [Postingan] [Event]           │
├─────────────────────────────────────┤
│ CONTENT (user's posts or events)    │
└─────────────────────────────────────┘
```

#### Mode B: Other User's Profile (`/profile/:userId`)

- Same layout BUT:
- [←] Back instead of [⋮] menu
- [IKUTI] or [MENGIKUTI] instead of [EDIT]
- Double tap to unfollow (with confirmation)

### Actions

| Element | Action |
|---------|--------|
| [⋮] Menu | Bottom sheet: Tiket, Transaksi, Pengaturan, Keluar |
| [AVATAR] | View full size |
| Stats | Tap to navigate (Followers → `/followers`) |
| [EDIT PROFIL] | → `/edit-profile` |
| [IKUTI] | Follow user |
| [MENGIKUTI] | Show "Batal mengikuti?" → Confirm |

### Bottom Sheet Menu (Own Profile)

| Option | Route |
|--------|-------|
| Tiket Saya | `/my-tickets` |
| Transaksi | `/transactions` |
| Pengaturan | `/settings` |
| Keluar | Show logout dialog |

### Tabs

- **Postingan**: User's posts list
- **Event**: Events hosted (grid)

### Empty States

| Tab | Empty Message |
|-----|---------------|
| Postingan | "Belum ada postingan" |
| Event | "Belum ada event" |

**Test Keys**: `profile_screen`, `edit_button`, `menu_button`, `follow_button`

---

## EDIT PROFILE (`/edit-profile`)

### Layout

```
┌─────────────────────────────────────────────┐
│ [✕] Edit Profile                   [DONE]  │
├─────────────────────────────────────────────┤
│            [PHOTO - 100px]                 │
│            [Change photo]                   │
├─────────────────────────────────────────────┤
│ Name         [User Name]         [🔒]      │
│ Bio          [Add bio...]          [>]      │
│ Phone        [Add phone]           [>]      │
│ Gender       [Select gender]       [>]      │
│ Date of Birth [Select date]        [>]      │
│ Location     [Add location]        [>]      │
├─────────────────────────────────────────────┤
│ INTERESTS:                               │
│ [Meetup] [Sports] [Workshop] [...]        │
└─────────────────────────────────────────────┘
```

### Field Actions

| Field | Action | Note |
|-------|--------|------|
| Name | Disabled | Locked from Google |
| Bio | Dialog edit | Max 150 chars |
| Phone | Dialog edit | Numbers only |
| Gender | Radio selection | 4 options |
| DOB | Date picker | 1950 - now |
| Location | Dialog or GPS | Auto-detect |
| Photo | Camera/Gallery | TODO: V1 not upload |
| Interests | Toggle selection | Predefined list |

### Save Actions

1. Tap [DONE] → Show loading
2. Save to API
3. Success → Snackbar → Back to profile
4. Failed → Error message → Stay on screen

### Discard Changes

- Tap [✕] with unsaved changes
- Dialog: "Discard changes?" [Keep Editing] [Discard]

**Test Keys**: `edit_profile_screen`, `save_button`, `cancel_button`

---

## SETTINGS SCREEN (`/settings`)

### Layout

```
┌─────────────────────────────────────┐
│ [←] Pengaturan                      │
├─────────────────────────────────────┤
│ ACCOUNT                             │
│   Email    [user@gmail.com]    [🔒] │
│   Phone    [Add phone]         [>] │
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
│ ACCOUNT                             │
│   Log Out                     [>] │
└─────────────────────────────────────┘
```

**Note**: V1 does not support password change (Google Sign-In only) or account deletion. See [`10_non_goals.md`](../10_non_goals.md).

### Logout Dialog

```
┌─────────────────────────────────────┐
│                                     │
│     Yakin mau keluar?               │
│                                     │
│           [Batal]    [Keluar]       │
│                                     │
└─────────────────────────────────────┘
```

### Logout Flow

1. Clear local auth data
2. Sign out from Google
3. Navigate to `/login`

**Test Keys**: `settings_screen`, `logout_button`

---

## FOLLOWERS/FOLLOWING (`/profile/:id/followers`)

### Layout

```
┌─────────────────────────────────────┐
│ [←] Followers (120)                │
├─────────────────────────────────────┤
│ USER LIST:                          │
│ ┌─────────────────────────────────┐ │
│ │ [Avatar] [Name]    [Following+] │ │
│ │ [Location]                      │ │
│ └─────────────────────────────────┘ │
│ ...more users...                    │
└─────────────────────────────────────┘
```

### Actions

- Tap user → Go to their profile
- Tap [Following+] → Follow back

**Test Keys**: `followers_screen`, `user_item_{$id}`

---

## FLOW DIAGRAM

```
Profile (own) → Tap Menu → Bottom Sheet
                   ├─→ My Tickets
                   ├─→ Transactions
                   ├─→ Settings → Tap Logout → Dialog → Login
                   └─→ Edit Profile → Save → Back to Profile

Profile (other) → Tap Follow → Update button
                → Tap Stats → Followers/Following screen
```

---

## IMPLEMENTATION

**Files**:
- `lib/presentation/pages/profile/profile_screen.dart`
- `lib/presentation/pages/profile/edit_profile_screen.dart`
- `lib/presentation/pages/settings/settings_screen.dart`
- `lib/presentation/pages/profile/followers_following_screen.dart`

**BLoCs**:
- `lib/presentation/bloc/user/user_bloc.dart`
- `lib/presentation/bloc/auth/auth_bloc.dart`
