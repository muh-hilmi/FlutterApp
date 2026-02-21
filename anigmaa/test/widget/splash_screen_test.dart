/// ============================================================
/// SPLASH SCREEN WIDGET TESTS
/// ============================================================
///
/// Test ini memverifikasi tampilan awal Splash Screen.
/// Kita hanya test frame pertama (sebelum async auth logic jalan)
/// karena auth logic memerlukan backend.
///
/// Jalankan dengan:
///   flutter test test/widget/splash_screen_test.dart
/// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anigmaa/core/auth/auth_bloc.dart';
import 'package:anigmaa/core/auth/auth_state.dart';
import 'package:anigmaa/core/services/auth_service.dart';
import 'package:anigmaa/core/utils/app_logger.dart';
import 'package:anigmaa/presentation/pages/splash/splash_screen.dart';
import 'package:anigmaa/injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../helpers/mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockAuthRemoteDataSource mockAuthDataSource;
  late AuthBloc authBloc;

  setUpAll(() {
    AppLogger().init();
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockAuthDataSource = MockAuthRemoteDataSource();

    // Stub hasValidToken supaya tidak crash saat async jalan
    when(() => mockAuthService.hasValidToken)
        .thenAnswer((_) async => false);

    authBloc = AuthBloc(mockAuthService, mockAuthDataSource);

    // Register di GetIt supaya SplashScreen bisa akses
    if (!di.sl.isRegistered<AuthService>()) {
      di.sl.registerSingleton<AuthService>(mockAuthService);
    }
    if (!di.sl.isRegistered<AuthBloc>()) {
      di.sl.registerSingleton<AuthBloc>(authBloc);
    }
  });

  tearDown(() async {
    await authBloc.close();
    // Unregister supaya test berikutnya bersih
    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    if (di.sl.isRegistered<AuthService>()) di.sl.unregister<AuthService>();
  });

  /// Helper: buat widget tree minimal yang dibutuhkan SplashScreen
  Widget buildSplashApp() {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const MaterialApp(
        home: SplashScreen(),
      ),
    );
  }

  group('Splash Screen UI', () {
    testWidgets('splash screen menggunakan key yang benar', (tester) async {
      await tester.pumpWidget(buildSplashApp());
      // Hanya render frame pertama (tidak await settle karena ada timer 1.5s)
      await tester.pump();

      expect(find.byKey(const Key('splash_screen')), findsOneWidget);
    });

    testWidgets('menampilkan nama app "flyerr"', (tester) async {
      await tester.pumpWidget(buildSplashApp());
      await tester.pump();

      expect(find.text('flyerr'), findsOneWidget);
    });

    testWidgets('menampilkan subtitle teks', (tester) async {
      await tester.pumpWidget(buildSplashApp());
      await tester.pump();

      expect(
        find.text('Cari acara seru di sekitar lo 🎉'),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan loading indicator', (tester) async {
      await tester.pumpWidget(buildSplashApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('status text awal adalah "Menyiapkan..."', (tester) async {
      await tester.pumpWidget(buildSplashApp());
      await tester.pump();

      expect(find.text('Menyiapkan...'), findsOneWidget);
    });

    testWidgets('menampilkan icon event di logo', (tester) async {
      await tester.pumpWidget(buildSplashApp());
      await tester.pump();

      expect(find.byIcon(Icons.event), findsOneWidget);
    });
  });
}
