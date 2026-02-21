/// ============================================================
/// FLOW 04: PROFILE SCREEN INTEGRATION TEST
/// ============================================================
///
/// Test halaman Profile — lihat profil, data user, stats.
///
/// ⚠️  PRASYARAT: User harus sudah login.
///
/// Cara menjalankan:
///   flutter test integration_test/flows/04_profile_test.dart -d <device_id>
/// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'package:anigmaa/main.dart' as app;
import '../helpers/integration_test_setup.dart';

const String _testAccessToken = 'GANTI_DENGAN_TOKEN_VALID';
const String _testRefreshToken = 'GANTI_DENGAN_REFRESH_TOKEN_VALID';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flow 04 - Profile Screen', () {
    setUp(() async {
      if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') return;
      await TestSetup.loggedInWithToken(
        accessToken: _testAccessToken,
        refreshToken: _testRefreshToken,
        userName: 'Test User',
        userEmail: 'test@example.com',
      );
    });

    /// Helper: launch app dan navigasi ke tab Profile
    Future<void> goToProfileTab(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));
      await tester.tap(find.byKey(const Key('profile_tab')));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    testWidgets(
      '04.01 - Profile screen bisa dibuka',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi');
          return;
        }
        await goToProfileTab(tester);

        expect(
          find.byKey(const Key('profile_screen')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '04.02 - Nama user muncul di profile',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi');
          return;
        }
        await goToProfileTab(tester);

        expect(
          find.byKey(const Key('profile_name')),
          findsOneWidget,
          reason: 'Nama user harus muncul di profil',
        );
      },
    );
  });
}
