# 07. QA STRATEGY

Testing requirements and reporting structure.

---

## TEST COVERAGE REQUIREMENTS (V1)

### Critical Flows (Must Pass)

| Flow | Priority | Status |
|------|----------|--------|
| **Auth Flow (New User)** | P0 | ⬜ Pending |
| Onboarding → Login → Complete Profile → Home | | |
| + Edge cases: cancel, skip, error, permission denied | | |
| **Auth Flow (Returning)** | P0 | ⬜ Pending |
| Open app → Auto-login → Home | | |
| + Session expired handling | | |
| **Event Discovery** | P0 | ⬜ Pending |
| Home → Scroll feed → Tap event → View details | | |
| Discover → Filter → Swipe cards → Tap event | | |
| **Ticket Purchase** | P0 | ⬜ Pending |
| Event detail → Select ticket → Buy → Success | | |
| + Payment failed, cancelled, timeout scenarios | | |
| **Profile Management** | P1 | ⬜ Pending |
| View profile → Edit → Save → Verify | | |
| View other profile → Follow → Unfollow | | |
| **Check-in Flow** | P1 | ⬜ Pending |
| My tickets → Tap QR → Show QR → Simulate scan | | |
| **Social Features** | P1 | ⬜ Pending |
| Create post → Add photo → Post → Verify in feed | | |
| Like post → Comment → Share | | |
| **Navigation** | P1 | ⬜ Pending |
| All bottom nav tabs work | | |
| All back buttons work | | |
| **Error Handling** | P1 | ⬜ Pending |
| Server unavailable scenarios | | |
| Network timeout, permission denied | | |

---

## APPIUM E2E TESTS

### Setup

**Required**: Appium server running on `http://localhost:4723/wd/hub`

**Installation**:
```bash
npm install -g appium
appium driver install uiautomator2
```

### Test Structure

```
test_driver/
├── appium_setup.dart       # Configuration
├── tests/
│   ├── 01_auth_flow_test.dart       # Auth scenarios
│   ├── 02_event_flow_test.dart      # Event & tickets
│   ├── 03_profile_flow_test.dart    # Profile & settings
│   ├── 04_social_flow_test.dart     # Posts & comments
│   └── 05_navigation_test.dart      # Nav & edge cases
└── helpers/
    └── test_helpers.dart   # Reusable helpers
```

### Running Tests

```bash
# Start Appium
appium

# Run tests
flutter drive --target=test_driver/tests/01_auth_flow_test.dart
```

---

## TEST KEY REQUIREMENTS

Every interactive element MUST have a `Key()`:

```dart
// ✅ GOOD
ElevatedButton(
  key: Key('google_sign_in_button'),
  onPressed: () {},
  child: Text('Sign in'),
)

// ❌ BAD
ElevatedButton(
  onPressed: () {},
  child: Text('Sign in'),
)
```

### Required Keys by Screen

| Screen | Required Keys |
|--------|---------------|
| Splash | `splash_screen` |
| Onboarding | `onboarding_screen`, `start_button` |
| Login | `login_screen`, `google_sign_in_button` |
| Complete Profile | `complete_profile_screen`, `dob_field`, `location_field`, `submit_button`, `skip_button` |
| Home | `home_screen`, `feed_tab`, `events_tab`, `fab_button` |
| Discover | `discover_screen`, `search_bar` |
| Event Detail | `event_detail_screen`, `buy_button`, `back_button` |
| Profile | `profile_screen`, `edit_button`, `menu_button`, `follow_button` |
| Settings | `settings_screen`, `logout_button` |

---

## QA REPORT STRUCTURE

### Folder Structure

```
qa_reports/
├── appium/
│   ├── YYYY-MM-DD/
│   │   ├── 01_auth_flow/
│   │   │   ├── run_001.json           # Test results
│   │   │   ├── screenshots/
│   │   │   │   ├── 01_onboarding.png
│   │   │   │   ├── 02_login.png
│   │   │   │   ├── 03_complete_profile.png
│   │   │   │   └── 04_home.png
│   │   │   ├── logs/
│   │   │   │   └── appium.log
│   │   │   └── summary.md
│   │   │
│   │   ├── 02_event_flow/
│   │   │   ├── run_001.json
│   │   │   ├── screenshots/
│   │   │   ├── logs/
│   │   │   └── summary.md
│   │   │
│   │   └── 03_regression/
│   │       ├── run_001.json
│   │       └── summary.md
│   │
├── manual/
│   └── YYYY-MM-DD/
│       ├── ux_audit.md
│       └── smoke_test.md
│
└── index.md               # Master index
```

### Report Template

```markdown
# Test Report: {Flow Name}

**Date**: YYYY-MM-DD
**Tester**: {Name}
**Build**: {Version}

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 25 |
| Passed | 23 |
| Failed | 2 |
| Skipped | 0 |
| Pass Rate | 92% |

## Failed Tests

| Test | Error | Screenshot |
|------|-------|------------|
| AuthFlow_005 | Timeout | auth_005_error.png |

## Issues Found

| Severity | Issue | Status |
|----------|-------|--------|
| High | Profile completion not saving | Open |

## Screenshots

(Attach relevant screenshots)

## Recommendations

- Fix profile completion issue
- Add retry logic for network errors
```

---

## MANUAL QA CHECKLIST

### Smoke Test (Every Build)

- [ ] App launches without crash
- [ ] Can login with Google
- [ ] Home screen loads
- [ ] Can view event details
- [ ] Can view own profile
- [ ] Can logout

### Full Regression (Before Release)

- [ ] All auth flows work
- [ ] All event flows work
- [ ] All profile flows work
- [ ] All social flows work
- [ ] All navigation works
- [ ] All error states handle correctly

### UX Audit (Weekly)

- [ ] Loading states are clear
- [ ] Error messages are helpful
- [ ] Empty states have CTAs
- [ ] Transitions are smooth
- [ ] No layout issues
- [ ] Text is readable

---

## CONTINUOUS TESTING

### Pre-Commit

```bash
# Run locally before committing
flutter test                    # Unit tests
flutter analyze                # Linting
dart format .                  # Formatting
```

### CI/CD (Future)

```yaml
# .github/workflows/test.yml
on: [push, pull_request]
jobs:
  test:
    - flutter test
    - flutter analyze
    - appium e2e tests
```

---

## TEST DATA MANAGEMENT

### Test Users

| Type | Email | Password |
|------|-------|----------|
| New user | test_new@example.com | *Google auth* |
| Existing | test_existing@example.com | *Google auth* |
| With tickets | test_tickets@example.com | *Google auth* |

### Test Events

| Event | ID | Price | Status |
|-------|----|-------|--------|
| Free event | event_free_001 | Gratis | Available |
| Paid event | event_paid_001 | Rp 150k | Available |
| Sold out | event_sold_001 | Rp 200k | Sold out |
| Past event | event_past_001 | Rp 100k | Ended |

---

## BUG REPORTING

### Bug Template

```markdown
## Bug Description

**Summary**: {Short description}

**Steps to Reproduce**:
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Expected**: {What should happen}
**Actual**: {What actually happens}

**Environment**:
- App version: {1.0.0}
- Device: {Pixel 5}
- OS: {Android 13}

**Severity**: {Critical/High/Medium/Low}
**Attachments**: {Screenshots, logs}
```

---

## PERFORMANCE TARGETS

| Metric | Target | Measurement |
|--------|--------|-------------|
| App launch | < 3 seconds | Time to home screen |
| API response | < 2 seconds | All endpoints |
| Screen transition | < 300ms | Perceived smoothness |
| Image load | < 5 seconds | Progressive loading |

---

## IMPLEMENTATION

**QA Tools**:
- Appium for E2E
- flutter_test for unit/widget
- integration_test for integration tests

**Test Command**:
```bash
flutter test test/unit/
flutter test test/widget/
flutter test test_driver/
```

---

**Remember**: Tests = Confidence = Production Ready
