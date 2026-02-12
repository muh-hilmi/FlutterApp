import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Auth Flow E2E Tests for Anigmaa using Flutter Driver
///
/// Tests Flow 01 (New User):
/// 1. Fresh install shows onboarding
/// 2. Onboarding to login navigation
/// 3. Login screen elements
///
/// Run with:
/// flutter drive --device-id=emulator-5554 --target=test_driver/test_entry_point.dart --driver=test_driver/tests/01_auth_flow_test.dart
///
/// Prerequisites:
/// - App must be built in debug mode
/// - Clear app data for true "new user" test: adb shell pm clear com.example.anigmaa
/// - Backend server should be running for full E2E tests

void main() {
  late FlutterDriver driver;

  group('Flow 01: New User Auth Flow', () {
    setUpAll(() async {
      // Connect to the Flutter app
      driver = await FlutterDriver.connect();

      // Wait for app to fully start and stabilize
      // Splash screen takes ~1.5s + navigation + onboarding animation
      await Future.delayed(const Duration(seconds: 5));
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });

    test('test_fresh_install_shows_onboarding', () async {
      print('\n📱 Test: Fresh install shows onboarding screen');

      // After splash, we should see onboarding screen (for fresh install)
      final onboardingFinder = find.byValueKey('onboarding_screen');

      try {
        await driver.waitFor(onboardingFinder, timeout: const Duration(seconds: 15));
        print('✓ Onboarding screen displayed for fresh user');

        // Verify we can see the "Gas Mulai!" button exists
        final startButtonFinder = find.byValueKey('start_button');
        await driver.waitFor(startButtonFinder, timeout: const Duration(seconds: 2));
        print('✓ "Gas Mulai!" button is present');

        // Verify the button text by finding the text widget
        final buttonTextFinder = find.text('Gas Mulai!');
        await driver.waitFor(buttonTextFinder, timeout: const Duration(seconds: 2));
        print('✓ "Gas Mulai!" button text verified');

      } catch (e) {
        print('⚠ Onboarding test failed: $e');
        print('   For a true fresh install test, clear app data: adb shell pm clear com.example.anigmaa');
        rethrow;
      }
    });

    test('test_onboarding_to_login', () async {
      print('\n📱 Test: Onboarding to login navigation');

      final startButtonFinder = find.byValueKey('start_button');
      final loginScreenFinder = find.byValueKey('login_screen');

      try {
        // Wait for onboarding animation to complete (1.2s animation + buffer)
        await Future.delayed(const Duration(milliseconds: 1500));

        // Tap start button
        await driver.tap(startButtonFinder);
        print('✓ Tapped "Gas Mulai!" button');

        // Wait for navigation to complete
        await Future.delayed(const Duration(seconds: 3));

        // Verify we're now on login screen
        await driver.waitFor(loginScreenFinder, timeout: const Duration(seconds: 10));
        print('✓ Navigated to login screen');

        // Verify Google Sign In button is present
        final googleButtonFinder = find.byValueKey('google_sign_in_button');
        await driver.waitFor(googleButtonFinder, timeout: const Duration(seconds: 2));
        print('✓ Google Sign In button is present');

        // Verify button text
        final buttonTextFinder = find.text('Lanjut pake Google');
        await driver.waitFor(buttonTextFinder, timeout: const Duration(seconds: 2));
        print('✓ Google Sign In button text verified');

      } catch (e) {
        print('⚠ Navigation test failed: $e');
        rethrow;
      }
    });

    test('test_login_screen_elements', () async {
      print('\n📱 Test: Login screen elements verification');

      try {
        // Verify app name
        final appNameFinder = find.text('flyerr');
        await driver.waitFor(appNameFinder, timeout: const Duration(seconds: 2));
        print('✓ App name "flyerr" is displayed');

        // Verify tagline
        final taglineFinder = find.text('Temuin acara seru, bikin kenangan baru 🚀');
        await driver.waitFor(taglineFinder, timeout: const Duration(seconds: 2));
        print('✓ Tagline is displayed');

        // Verify Google Sign In button text
        final googleButtonTextFinder = find.text('Lanjut pake Google');
        await driver.waitFor(googleButtonTextFinder, timeout: const Duration(seconds: 2));
        print('✓ Google Sign In button text is correct');

        print('✓ All login screen elements verified');

      } catch (e) {
        print('⚠ Login screen verification failed: $e');
        rethrow;
      }
    });

    test('test_take_screenshot', () async {
      print('\n📱 Test: Take screenshot for debugging');

      try {
        final bytes = await driver.screenshot();
        print('✓ Screenshot taken (${bytes.length} bytes)');
        print('ℹ Screenshots can be saved to file for debugging');
      } catch (e) {
        print('⚠ Screenshot failed: $e');
      }
    });
  });
}
