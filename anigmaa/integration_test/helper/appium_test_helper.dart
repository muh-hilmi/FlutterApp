import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anigmaa/main.dart' as app;
import 'package:flutter/material.dart';

/// Appium Test Helper
///
/// Provides utilities for running Appium E2E tests with Flutter
class AppiumTestHelper {
  /// Initialize the app for testing
  // static WidgetTester? _tester; // Reserved for future use
  static bool _initialized = false;

  /// Setup test environment
  static Future<void> setup() async {
    if (_initialized) return;
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    _initialized = true;
  }

  /// Launch app
  static Future<void> launchApp(WidgetTester tester) async {
    // _tester = tester; // Reserved for future use
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Wait for widget to appear
  static Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tryEvaluate(finder) != null) {
        return;
      }
    }
    throw TimeoutException(
      'Widget not found within ${timeout.inSeconds} seconds',
      timeout,
    );
  }

  /// Tap and wait for navigation
  static Future<void> tapAndWait(
    WidgetTester tester,
    Finder finder, {
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(delay);
  }

  /// Enter text with optional clear
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text, {
    bool clearFirst = true,
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();

    if (clearFirst) {
      await tester.enterText(finder, '');
      await tester.pumpAndSettle();
    }

    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scroll until widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder scrollable,
    Finder target, {
    double delta = -100.0,
    int maxScrolls = 50,
  }) async {
    for (int i = 0; i < maxScrolls; i++) {
      try {
        await waitFor(tester, target, timeout: const Duration(seconds: 1));
        return;
      } catch (_) {
        await tester.drag(scrollable, Offset(0, delta));
        await tester.pumpAndSettle();
      }
    }
    throw Exception('Widget not found after $maxScrolls scrolls');
  }

  /// Take screenshot (for integration test)
  static Future<void> takeScreenshot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
  }

  static IntegrationTestWidgetsFlutterBinding get binding {
    return IntegrationTestWidgetsFlutterBinding.instance;
  }

  /// Try to evaluate finder without throwing
  static Widget? tryEvaluate(Finder finder) {
    try {
      return finder.evaluate().single.widget;
    } catch (_) {
      return null;
    }
  }

  /// Check if widget exists
  static bool exists(Finder finder) {
    return tryEvaluate(finder) != null;
  }

  /// Wait for loading to complete
  static Future<void> waitForLoading(
    WidgetTester tester, {
    Finder? loadingIndicator,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final finder =
        loadingIndicator ??
        find.byWidgetPredicate(
          (widget) =>
              widget is CircularProgressIndicator ||
              widget is LinearProgressIndicator ||
              (widget is Center && widget.child is CircularProgressIndicator),
        );

    try {
      await waitFor(tester, finder, timeout: timeout);
      // Wait for it to disappear
      final endTime = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(endTime)) {
        await tester.pump(const Duration(milliseconds: 100));
        if (tryEvaluate(finder) == null) {
          return;
        }
      }
    } catch (_) {
      // Loading indicator might not be present
    }
  }
}

/// Custom finders for Anigmaa app
class AnigmaaFinders {
  // Navigation
  static final homeTab = find.text('Home');
  static final discoverTab = find.text('Discover');
  static final nearbyTab = find.text('Nearby');
  static final profileTab = find.text('Profile');
  static final settingsTab = find.text('Settings');

  // FAB (Floating Action Button)
  static final fab = find.byType(FloatingActionButton);

  // Event creation
  static final createEventButton = find.text('Buat Event');
  static final createEventButtonAlt = find.text('Create Event');
  static final submitEventButton = find.text('Buat Event! 🎉');
  static final submitEventButtonAlt = find.text('Create Event!');

  // Conversation flow
  static final hiGreeting = find.text('Halo! 👋');
  static final readyButton = find.text('Siap! 🚀');
  static final readyButtonAlt = find.text('Ready!');

  // Form inputs
  static final titleInput = find.byKey(const Key('event_title_input'));
  static final descriptionInput = find.byKey(
    const Key('event_description_input'),
  );
  static final locationPicker = find.text('Pilih Lokasi 📍');
  static final locationPickerAlt = find.text('Pick Location 📍');
  static final datePicker = find.text('Pilih Tanggal 📅');
  static final datePickerAlt = find.text('Pick Date 📅');
  static final timePicker = find.text('Pilih Waktu ⏰');
  static final timePickerAlt = find.text('Pick Time ⏰');

  // Category selection
  static final categoryMeetup = find.text('Meetup');
  static final categoryWorkshop = find.text('Workshop');
  static final categoryParty = find.text('Party');
  static final categorySports = find.text('Sports');
  static final categoryOther = find.text('Other');

  // Event detail
  static final joinButton = find.text('Join Event');
  static final joinButtonAlt = find.text('Daftar');
  static final interestButton = find.byIcon(Icons.favorite_border);
  static final shareButton = find.byIcon(Icons.share);
  static final shareButtonAlt = find.byIcon(Icons.ios_share);

  // Share dialog
  static final shareDialogTitle = find.text('Bagikan Event');
  static final shareDialogTitleAlt = find.text('Share Event');
  static final copyLinkButton = find.text('Salin Link');
  static final copyLinkButtonAlt = find.text('Copy Link');

  // Payment
  static final payButton = find.text('Bayar Sekarang');
  static final payButtonAlt = find.text('Pay Now');
  static final qrisOption = find.text('QRIS');
  static final gopayOption = find.text('GoPay');
  static final danaOption = find.text('DANA');
  static final ovoOption = find.text('OVO');
  static final shopeePayOption = find.text('ShopeePay');

  // Auth
  static final loginButton = find.text('Login');
  static final loginButtonAlt = find.text('Masuk');
  static final googleSignInButton = find.text('Sign in with Google');
  static final emailInput = find.byKey(const Key('email_input'));
  static final passwordInput = find.byKey(const Key('password_input'));

  // Snackbars
  static final successSnackbar = find.text('Link event disalin!');
  static final successSnackbarAlt = find.text('Link copied!');
  static final errorSnackbar = find.textContaining('Error');

  // Common
  static final okButton = find.text('OK');
  static final cancelButton = find.text('Cancel');
  static final cancelButtonAlt = find.text('Batal');
  static final continueButton = find.text('Continue');
  static final continueButtonAlt = find.text('Lanjut');

  // Loading
  static final loadingIndicator = find.byWidgetPredicate(
    (widget) =>
        widget is CircularProgressIndicator ||
        widget is LinearProgressIndicator,
  );
}

/// Test timeout exception
class TimeoutException implements Exception {
  final String message;
  final Duration duration;

  TimeoutException(this.message, this.duration);

  @override
  String toString() =>
      'TimeoutException: $message (after ${duration.inSeconds}s)';
}
