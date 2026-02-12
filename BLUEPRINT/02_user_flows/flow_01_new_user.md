# FLOW 1: First Time User

**Journey**: Download → Home

---

## SCREENS

### 1. Splash (`/splash`)

**Purpose**: Determine where to route user

**State**: Loading (3 sec)

**Checks**:
- Has stored token?
- Seen onboarding?
- Location permission?

**Transitions**:
| Condition | Route |
|-----------|-------|
| No token + no onboarding | `/onboarding` |
| No token + seen onboarding | `/login` |
| Has token + valid | `/home` |
| Has token + invalid | `/login` |
| Server error | `/server_unavailable` |

**Test Keys**: `splash_screen`

---

### 2. Onboarding (`/onboarding`)

**Content**:
- Icon: Rocket
- Title: "Halo, Selamat Datang di Anigmaa"
- Subtitle: "Cari event seru di sekitarmu"

**Actions**:
- Tap "Gas Mulai!" → `/login`

**Edge Cases**:
- User closes app → Next open goes to `/login` (remember state)
- Back button → Disabled

**State Flags**:
- `hasSeenOnboarding = true` (SharedPreferences)

**Test Keys**: `onboarding_screen`, `start_button`

---

### 3. Login (`/login`)

**Content**:
- Logo Anigmaa
- Title: "Masuk untuk mulai"
- [Google Sign In] button

**Actions**:
- Tap Google Sign In → Open Google Auth

**User Detection Logic**:
```
IF (account_created < 1 min ago AND no dateOfBirth)
    → /complete-profile
ELSE
    → /home
```

**Error Handling**:
- Auth failed → Snackbar "Coba lagi"
- Network error → Snackbar "Cek koneksi"
- Server down → `/server_unavailable`

**Test Keys**: `login_screen`, `google_sign_in_button`

---

### 4. Complete Profile (`/complete-profile`)

**Content**:
- Title: "Lengkapin Profil Lo"
- Subtitle: "Biar kita bisa rekomendasiin event"

**Fields** (Required marked *):
- [Date of Birth *] "Pilih tanggal lahir lo"
- [Gender] "Pilih gender"
- [Location *] "Izinkan akses lokasi"
- [Phone] "08123456789"

**Buttons**:
- [PRIMARY] "Lanjut" → Save → `/home`
- [SECONDARY] "Skip dulu" → `/home` (profile incomplete)

**Validation**:
- DOB required → Show error "Pilih tanggal lahir"
- Location required → Show error "Izinkan lokasi"
- Gender/Phone optional

**Location Permission Flow**:
1. Tap field → Request permission
2. Allow → GPS → Geocode → Show "Jakarta"
3. Deny → Error "Lokasi wajib"
4. Deny forever → Open app settings

**After Save**:
- Update AuthService with new user data
- Navigate to `/home` with fresh data

**Test Keys**: `complete_profile_screen`, `dob_field`, `location_field`, `submit_button`, `skip_button`

---

### 5. Home (`/home`)

See [Flow 2: Home](../flow_02_home.md)

---

## FLOW DIAGRAM

```
Download App
     ↓
  SPLASH
     ↓
No token?
     ↓
 ONBOARDING → remember:seen=true
     ↓
   LOGIN
     ↓
Google Auth Success
     ↓
  New User? ──Yes→ COMPLETE PROFILE ──┐
     │No                            │
     ↓                              │
   HOME ←────────────────────────────┘
```

---

## EDGE CASES

| Scenario | Behavior |
|----------|----------|
| User closes app during onboarding | Next open goes to login |
| Google auth fails | Retry allowed, error message |
| Profile completion skipped | Can access home, limited recommendations |
| Location denied forever | Open app settings |
| Server down during login | Show server_unavailable screen |
| Token expires | Show login again |

---

## IMPLEMENTATION NOTES

**Files**:
- `lib/presentation/pages/splash/splash_screen.dart`
- `lib/presentation/pages/auth/onboarding_screen.dart`
- `lib/presentation/pages/auth/login_screen.dart`
- `lib/presentation/pages/auth/complete_profile_screen.dart`

**BLoCs**:
- `lib/presentation/bloc/auth/auth_bloc.dart` - Auth state
- `lib/presentation/bloc/user/user_bloc.dart` - User profile

**Services**:
- `lib/core/services/auth_service.dart` - Token storage
- `lib/core/services/google_auth_service.dart` - Google auth
