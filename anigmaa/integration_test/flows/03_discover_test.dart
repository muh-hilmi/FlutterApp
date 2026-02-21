/// ============================================================
/// FLOW 03: DISCOVER SCREEN INTEGRATION TEST
/// ============================================================
///
/// Test untuk halaman Discover — cari event, filter, lihat peta.
///
/// ⚠️  PRASYARAT: User harus sudah login (sama seperti flow 02).
///
/// Cara menjalankan:
///   flutter test integration_test/flows/03_discover_test.dart -d <device_id>
/// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'package:anigmaa/main.dart' as app;
import '../helpers/integration_test_setup.dart';

// Gunakan token yang sama dengan flow 02
const String _testAccessToken = 'GANTI_DENGAN_TOKEN_VALID';
const String _testRefreshToken = 'GANTI_DENGAN_REFRESH_TOKEN_VALID';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flow 03 - Discover Screen', () {
    setUp(() async {
      if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') return;
      await TestSetup.loggedInWithToken(
        accessToken: _testAccessToken,
        refreshToken: _testRefreshToken,
      );
    });

    /// Helper: launch app dan navigasi ke tab Discover
    Future<void> goToDiscoverTab(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));
      await tester.tap(find.byKey(const Key('events_tab')));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    testWidgets(
      '03.01 - Discover screen bisa dibuka dari bottom nav',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi');
          return;
        }
        await goToDiscoverTab(tester);

        // Discover screen harus sudah render (tidak ada splash)
        expect(find.byKey(const Key('splash_screen')), findsNothing);
      },
    );

    testWidgets(
      '03.02 - Search bar tersedia di discover screen',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi');
          return;
        }
        await goToDiscoverTab(tester);

        // Cari search field
        expect(
          find.byType(TextField),
          findsWidgets,
          reason: 'Harus ada search bar di discover screen',
        );
      },
    );

    testWidgets(
      '03.03 - Bisa mengetik di search bar',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi');
          return;
        }
        await goToDiscoverTab(tester);

        // Cari dan tap search field
        final searchField = find.byType(TextField).first;
        await tester.tap(searchField);
        await tester.pumpAndSettle();

        // Ketik teks pencarian
        await tester.enterText(searchField, 'konser');
        await tester.pumpAndSettle();

        // Teks harus muncul di field
        expect(find.text('konser'), findsOneWidget);
      },
    );

    testWidgets(
      '03.04 - Filter category pills tersedia',
      (tester) async {
        if (_testAccessToken == 'GANTI_DENGAN_TOKEN_VALID') {
          markTestSkipped('Token belum diisi');
          return;
        }
        await goToDiscoverTab(tester);

        // Cek ada teks kategori
        // Filter pills: "Semua", "Belajar", "Nongkrong", dll
        expect(
          find.text('Semua'),
          findsOneWidget,
          reason: 'Filter "Semua" harus ada di discover screen',
        );
      },
    );
  });
}
