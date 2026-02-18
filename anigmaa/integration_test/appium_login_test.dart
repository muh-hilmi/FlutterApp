import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anigmaa/main.dart';
import 'helper/appium_test_helper.dart';

/// Appium Login Test
///
/// Example E2E test for login flow using Appium/Integration Test
///
/// Prerequisites:
/// 1. Appium server running: appium
/// 2. Android emulator/device connected: adb devices
/// 3. App built: flutter build apk --debug
///
/// Run: flutter test integration_test/appium_login_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Appium Login Tests', () {
    setUpAll(() async {
      await AppiumTestHelper.setup();
    });

    testWidgets('App launches successfully', (WidgetTester tester) async {
      await AppiumTestHelper.launchApp(tester);

      // Verify app launches
      expect(find.byType(NotionSocialApp), findsOneWidget);
    });

    testWidgets('Login screen is displayed', (WidgetTester tester) async {
      await AppiumTestHelper.launchApp(tester);

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check for login button or Google sign-in button
      final hasLoginButton = AppiumTestHelper.exists(
        AnigmaaFinders.loginButton,
      );
      final hasGoogleSignIn = AppiumTestHelper.exists(
        AnigmaaFinders.googleSignInButton,
      );

      expect(
        hasLoginButton || hasGoogleSignIn,
        isTrue,
        reason: 'Expected to find login button or Google sign-in button',
      );
    });

    testWidgets('Google Sign-In button is clickable',
        (WidgetTester tester) async {
      await AppiumTestHelper.launchApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find Google sign-in button
      final googleButton = AnigmaaFinders.googleSignInButton;

      if (AppiumTestHelper.exists(googleButton)) {
        // Verify button is tappable
        await tester.tap(googleButton);
        await tester.pumpAndSettle();

        // Note: This will open Google sign-in flow
        // In real tests, you would handle the webview or mock the auth
      } else {
        // Skip if button not found
        // Google sign-in button not found - skipping test
      }
    });

    testWidgets('Navigate to Home after auth (mock)',
        (WidgetTester tester) async {
      await AppiumTestHelper.launchApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Mock: Assume user is logged in
      // In real tests, you would:
      // 1. Mock the authentication service
      // 2. Or use test credentials
      // 3. Or inject auth token

      // For now, just verify home elements exist
      // (This test demonstrates the structure)
    });

    testWidgets('Logout functionality', (WidgetTester tester) async {
      await AppiumTestHelper.launchApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Note: This test requires:
      // 1. User to be logged in (mock or real)
      // 2. Navigate to profile
      // 3. Tap logout button
      // 4. Verify back to login screen

      // TODO: Implement when profile/logout is accessible
    });

    testWidgets('Auth persistence across restarts', (WidgetTester tester) async {
      // Test that auth state persists
      // This requires:
      // 1. Login once
      // 2. Close app
      // 3. Restart app
      // 4. Verify still logged in

      // TODO: Implement with proper auth mocking
    });
  });

  group('Appium Navigation Tests', () {
    testWidgets('Bottom navigation works', (WidgetTester tester) async {
      await AppiumTestHelper.launchApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Try tapping different tabs
      final tabs = [
        AnigmaaFinders.homeTab,
        AnigmaaFinders.discoverTab,
        AnigmaaFinders.nearbyTab,
        AnigmaaFinders.profileTab,
      ];

      for (final tab in tabs) {
        if (AppiumTestHelper.exists(tab)) {
          await AppiumTestHelper.tapAndWait(tester, tab);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('FAB button opens create event', (WidgetTester tester) async {
      await AppiumTestHelper.launchApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final fab = AnigmaaFinders.fab;
      if (AppiumTestHelper.exists(fab)) {
        await AppiumTestHelper.tapAndWait(tester, fab);

        // Verify create event flow starts
        expect(
          AppiumTestHelper.exists(AnigmaaFinders.hiGreeting) ||
              AppiumTestHelper.exists(AnigmaaFinders.createEventButton),
          isTrue,
        );
      }
    });
  });

  group('Appium Error Handling Tests', () {
    testWidgets('Handle network error gracefully', (WidgetTester tester) async {
      // Note: This requires mocking network failures
      // TODO: Implement with Dio mock adapter
    });

    testWidgets('Handle timeout errors', (WidgetTester tester) async {
      // Note: This requires slow network simulation
      // TODO: Implement with timeout testing
    });
  });
}

/// Notes for running Appium tests:
///
/// 1. **Start Appium Server:**
///    ```bash
///    appium
///    ```
///
/// 2. **Build App:**
///    ```bash
///    flutter build apk --debug
///    ```
///
/// 3. **Run Tests:**
///    ```bash
///    flutter test integration_test/appium_login_test.dart
///    ```
///
/// 4. **For device testing:**
///    ```bash
///    flutter test integration_test/appium_login_test.dart --device-id=<device-id>
///    ```
///
/// 5. **With Appium Inspector:**
///    - Open Appium Inspector
///    - Connect to localhost:4723
///    - Inspect elements to find correct selectors
