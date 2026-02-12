import 'package:flutter_test/flutter_test.dart' hide find;
import 'package:flutter_driver/flutter_driver.dart';

/// Helper functions for Appium/Flutter Driver tests
class TestHelpers {
  /// Wait for a widget to appear
  static Future<void> waitForWidget(
    FlutterDriver driver,
    SerializableFinder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await driver.waitFor(finder, timeout: timeout);
  }

  /// Tap a widget and wait for it to appear
  static Future<void> tapAndWait(
    FlutterDriver driver,
    SerializableFinder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await driver.tap(finder);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Enter text into a text field
  static Future<void> enterText(
    FlutterDriver driver,
    SerializableFinder finder,
    String text,
  ) async {
    await driver.tap(finder);
    await driver.enterText(text);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Scroll until a widget is found
  static Future<void> scrollUntilVisible(
    FlutterDriver driver,
    SerializableFinder scrollable,
    SerializableFinder target, {
    double dx = 0.0,
    double dy = -100.0,
    int maxScrolls = 50,
  }) async {
    for (int i = 0; i < maxScrolls; i++) {
      try {
        await driver.waitFor(target, timeout: const Duration(seconds: 1));
        return;
      } catch (_) {
        await driver.scroll(scrollable, dx, dy, Duration(milliseconds: 300));
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception('Widget not found after $maxScrolls scrolls');
  }

  /// Take screenshot
  static Future<void> takeScreenshot(FlutterDriver driver, String name) async {
    // driver.screenshot() returns List<int> (bytes)
    await driver.screenshot();
  }

  /// Wait for loading to complete
  static Future<void> waitForLoading(FlutterDriver driver) async {
    try {
      final loadingFinder = find.byValueKey('loading_indicator');
      await driver.waitForAbsent(
        loadingFinder,
        timeout: const Duration(seconds: 30),
      );
    } catch (_) {
      // Loading indicator might not be present
    }
  }
}

/// Custom finders for Anigmaa app
class AnigmaaFinders {
  // Common finders
  static final createEventButton = find.text('Buat Event');
  static final shareButton = find.byValueKey('share_button');
  static final paymentButton = find.text('Bayar Sekarang');
  static final submitEventButton = find.text('Buat Event! 🎉');
  static final nearbyEventsTab = find.text('Nearby');
  static final discoverTab = find.text('Discover');
  static final homeTab = find.text('Home');

  // Event detail finders
  static final joinEventButton = find.text('Join Event');
  static final interestButton = find.byValueKey('interest_button');

  // Form finders
  static final titleInput = find.byValueKey('event_title_input');
  static final descriptionInput = find.byValueKey('event_description_input');
  static final locationPicker = find.text('Pilih Lokasi 📍');

  // Payment finders
  static final qrisOption = find.text('QRIS');
  static final gopayOption = find.text('GoPay');
}
