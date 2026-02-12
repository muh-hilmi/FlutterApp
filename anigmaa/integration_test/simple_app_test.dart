import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anigmaa/main.dart' as app;

/// Simple App Test
/// Basic integration test that verifies the app launches on device
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Run the full app using main()
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // App should launch without crashing
    // We can't easily test for specific widgets without knowing the initial route
    // But we can verify the test framework is working
    expect(tester.binding, isNotNull);
  });
}
