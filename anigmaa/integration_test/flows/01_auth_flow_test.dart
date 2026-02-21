/// ============================================================
/// FLOW 01: AUTH FLOW INTEGRATION TEST
/// ============================================================
///
/// Test ini berjalan di EMULATOR asli — tidak perlu Appium.
///
/// Yang ditest:
///   1. App launch → Splash screen muncul
///   2. Tanpa token → Routing ke Login screen
///   3. Login screen memiliki elemen yang benar
///
/// Cara menjalankan (pastikan emulator nyala):
///   flutter test integration_test/flows/01_auth_flow_test.dart -d <device_id>
///
/// Lihat device_id dengan: flutter devices
/// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:anigmaa/main.dart' as app;
import '../helpers/integration_test_setup.dart';

void main() {
  // WAJIB: inisialisasi integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flow 01 - Auth Flow', () {
    // Setup dijalankan sebelum setiap test di group ini
    setUp(() async {
      // Reset ke kondisi: sudah lihat onboarding, belum login
      await TestSetup.seenOnboardingNotLoggedIn();
    });

    // ─── Test 1: Splash Screen Muncul ───────────────────────────────────────
    testWidgets(
      '01.01 - Splash screen muncul saat app pertama dibuka',
      (tester) async {
        app.main();
        await tester.pump(); // render frame pertama

        // Splash screen harus ada di layar
        expect(
          find.byKey(const Key('splash_screen')),
          findsOneWidget,
          reason: 'Splash screen harus tampil saat app pertama kali dibuka',
        );
      },
    );

    // ─── Test 2: Nama App di Splash ─────────────────────────────────────────
    testWidgets(
      '01.02 - Splash screen menampilkan nama app',
      (tester) async {
        app.main();
        await tester.pump();

        expect(
          find.text('flyerr'),
          findsOneWidget,
          reason: 'Nama app harus muncul di splash screen',
        );
      },
    );

    // ─── Test 3: Routing ke Login ────────────────────────────────────────────
    testWidgets(
      '01.03 - App routing ke Login screen setelah splash (tanpa token)',
      (tester) async {
        app.main();

        // Tunggu splash selesai (1.5 detik delay + animasi)
        // Timeout lebih panjang karena Google silent sign-in timeout 5 detik
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Seharusnya sudah di login screen sekarang
        expect(
          find.byKey(const Key('login_screen')),
          findsOneWidget,
          reason: 'Tanpa token → harus routing ke login screen',
        );
      },
    );

    // ─── Test 4: Elemen Login Screen ────────────────────────────────────────
    testWidgets(
      '01.04 - Login screen memiliki tombol Google Sign-In',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 8));

        expect(
          find.byKey(const Key('google_sign_in_button')),
          findsOneWidget,
          reason: 'Tombol Google Sign-In harus ada di login screen',
        );
      },
    );

    // ─── Test 5: Login Screen UI Lengkap ────────────────────────────────────
    testWidgets(
      '01.05 - Login screen menampilkan semua elemen UI penting',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Nama app
        expect(find.text('flyerr'), findsWidgets);

        // Tombol login
        expect(find.text('Lanjut pake Google'), findsOneWidget);

        // Privacy text
        expect(find.textContaining('Terms of Service'), findsOneWidget);
      },
    );
  });
}
