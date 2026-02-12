# FLOW 6: Edge Cases & Error Handling

**Journey**: When things go wrong

---

## SERVER UNAVAILABLE (`/server_unavailable`)

### When Shown

- API timeout (> 10 seconds)
- Network error (no internet)
- Server returns 5xx

### Layout

```
┌─────────────────────────────────────┐
│                                     │
│              🌐                    │
│                                     │
│   Gagal terhubung ke server        │
│   Cek koneksi internet kamu         │
│                                     │
├─────────────────────────────────────┤
│         [COBA LAGI]                 │
│                                     │
│      [LANJUT OFFLINE]               │
│                                     │
│     [KELUAR DARI AKUN]             │
│                                     │
└─────────────────────────────────────┘
```

### Actions

| Button | Action |
|--------|--------|
| [COBA LAGI] | Retry last API call |
| [LANJUT OFFLINE] | Show limited features (cached) |
| [KELUAR DARI AKUN] | Clear auth, go to `/login` |

### Offline Mode

- Show cached content only
- Disable actions requiring API
- Show "Offline mode" indicator
- Auto-retry when connection restored

**Test Keys**: `server_unavailable_screen`, `retry_button`

---

## PERMISSION HANDLING

### Location Permission

#### First Ask

```
┌─────────────────────────────────────┐
│                                     │
│  Anigmaa butuh akses lokasi         │
│  untuk rekomendasi event di         │
│  sekitarmu                          │
│                                     │
│      [IZINKAN]    [NANTI AJA]       │
│                                     │
└─────────────────────────────────────┘
```

#### Results

| Response | Action |
|----------|--------|
| Allow | Get GPS → Geocode → Show location |
| Deny | Use default location (Jakarta) |
| Deny forever | Open app settings dialog |

### Permission Strategy

| Permission | When to Ask | Fallback |
|------------|-------------|----------|
| Location | On first launch | Default to Jakarta |
| Camera | When adding photo (V2) | Disable photo upload |
| Notification | After first login (V2) | N/A |

---

## SESSION EXPIRED

### Detection

- API returns 401 (Unauthorized)
- Token refresh fails

### Flow

```
1. Intercept 401 error
2. Try token refresh
3. If refresh fails:
   ├─ Clear auth data
   ├─ Show dialog: "Sesi habis. Login lagi?"
   └─ [OK] → Navigate to /login
```

### Prevention

- Auto-refresh token 5 min before expiry
- Retry failed requests after refresh

---

## APP BACKGROUND/FOREGROUND

### User Minimizes App

- Save current state
- Pause ongoing operations
- Keep auth token in memory

### User Returns

| Time Away | Action |
|-----------|--------|
| < 5 min | Resume where left off |
| 5-60 min | Check session, resume if valid |
| > 60 min | Show lock screen (V2) |

---

## NETWORK ERROR STATES

### Per Screen

| Screen | Error State | Recovery |
|--------|-------------|----------|
| Home | "Gagal memuat. Tap untuk retry" | Tap to refresh |
| Event Detail | "Gagal memuat event. Coba lagi" | Pull to refresh |
| Ticket Purchase | "Gagal memuat tiket" | Retry button |
| Profile | "Gagal memuat profil" | Retry button |

### Global Error Handler

```dart
// In API interceptor
try {
  response = await dio.get(url);
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    showServerUnavailable();
  } else if (e.response?.statusCode == 401) {
    handleSessionExpired();
  } else {
    showGenericError();
  }
}
```

---

## VALIDATION ERRORS

### Complete Profile

| Field | Error Message |
|-------|---------------|
| DOB | "Pilih tanggal lahir" |
| Location | "Izinkan lokasi untuk rekomendasi" |

### Ticket Purchase

| Error | Message |
|-------|----------|
| Min 1 ticket | "Pilih minimal 1 tiket" |
| Max 10 tickets | "Maksimal 10 tiket" |

### Create Post

| Error | Message |
|-------|----------|
| Empty | "Tambahkan foto atau tulis sesuatu" |
| Too long | "Maksimal 500 karakter" |

---

## LOADING STATES

### Per Action

| Action | Loading State |
|--------|---------------|
| Submit profile | Disable all buttons, show spinner |
| Buy ticket | Full screen loader |
| Load feed | Skeleton or spinner at top |
| Refresh | Pull-to-refresh indicator |
| Infinite scroll | Spinner at bottom |

### Loading Best Practices

- Never block UI without feedback
- Show timeout after 10 seconds
- Allow cancellation on long operations

---

## EMPTY STATES

| Screen | Empty Message | Action |
|--------|---------------|--------|
| Feed | "Belum ada postingan" | CTA: Create first post |
| Events | "Belum ada event" | CTA: Browse discover |
| Tickets | "Belum ada tiket" | CTA: Find events |
| Comments | "Belum ada komentar" | CTA: Be first |
| Followers | "Belum ada follower" | N/A |

---

## IMPLEMENTATION

**Files**:
- `lib/presentation/pages/server_unavailable/server_unavailable_screen.dart`
- `lib/core/api/interceptors/error_interceptor.dart`
- `lib/core/api/interceptors/auth_interceptor.dart`

**BLoCs**:
- `lib/presentation/bloc/auth/auth_bloc.dart` - Session management
