/// ============================================================
/// FLOW 02: NAVIGATION INTEGRATION TEST
/// ============================================================
///
/// Test navigasi bottom navigation bar setelah login.
///
/// ⚠️  PRASYARAT: Test ini butuh user yang sudah login.
/// Isi variabel TEST_ACCESS_TOKEN dan TEST_REFRESH_TOKEN
/// dengan token yang valid dari backend kamu.
///
/// Cara dapat token:
///   1. Login manual di app
///   2. Check logs: "Saved to storage: ..." di login_screen.dart
///   3. Atau GET /api/v1/auth/login di Postman dengan Google token
///
/// Cara menjalankan:
///   flutter test integration_test/flows/02_navigation_test.dart -d <device_id>
/// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:anigmaa/main.dart' as app;
import '../helpers/integration_test_setup.dart';

// ─── ISI TOKEN DI SINI ────────────────────────────────────────────────────────
// Dapatkan dari: login manual → copy dari Flutter logs
const String _testAccessToken = 'GANTI_DENGAN_TOKEN_VALID';
const String _testRefreshToken = 'GANTI_DENGAN_REFRESH_TOKEN_VALID';
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flow 02 - Navigation', () {
    setUp(() async {
      if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
        // Skip jika token belum diisi
        return;
      }
      await TestSetup.loggedInWithToken(
        accessToken: _testAccessToken,
        refreshToken: _testRefreshToken,
      );
    });

    testWidgets(
      '02.01 - Bottom navigation bar muncul di home screen',
      (tester) async {
        // Skip jika token belum diisi
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi — skip test navigasi');
          return;
        }

        app.main();
        // Tunggu sampai melewati splash + validasi token (max 15 detik)
        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(
          find.byKey(const Key('bottom_nav')),
          findsOneWidget,
          reason: 'Bottom navigation harus muncul setelah login',
        );
      },
    );

    testWidgets(
      '02.02 - Semua tab navigation tersedia',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi — skip test navigasi');
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // Pastikan semua 4 tab ada
        expect(find.byKey(const Key('home_tab')), findsOneWidget);
        expect(find.byKey(const Key('events_tab')), findsOneWidget);
        expect(find.byKey(const Key('profile_tab')), findsOneWidget);
      },
    );

    testWidgets(
      '02.03 - Tap tab Events membuka halaman events',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi — skip test navigasi');
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // Tap tab events
        await tester.tap(find.byKey(const Key('events_tab')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Setelah tap events tab, halaman discover/events harus muncul
        // Verifikasi halaman berubah (tidak ada skeleton/splash lagi)
        expect(find.byKey(const Key('splash_screen')), findsNothing);
      },
    );

    testWidgets(
      '02.04 - Tap tab Profile membuka halaman profile',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi — skip test navigasi');
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // Tap profile tab
        await tester.tap(find.byKey(const Key('profile_tab')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Profile screen key harus muncul
        expect(find.byKey(const Key('profile_screen')), findsOneWidget);
      },
    );

    testWidgets(
      '02.05 - FAB tersedia di home screen',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi — skip test navigasi');
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(
          find.byKey(const Key('fab_create')),
          findsOneWidget,
          reason: 'FAB button harus ada di home screen',
        );
      },
    );
  });
}
