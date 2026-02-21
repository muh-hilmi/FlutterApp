/// ============================================================
/// LOGIN SCREEN WIDGET TESTS
/// ============================================================
///
/// Test tampilan dan interaksi Login Screen tanpa memerlukan
/// Google Sign-In asli atau koneksi ke backend.
///
/// Jalankan dengan:
///   flutter test test/widget/login_screen_test.dart
/// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:anigmaa/core/auth/auth_bloc.dart';
import 'package:anigmaa/core/services/google_auth_service.dart';
import 'package:anigmaa/core/utils/app_logger.dart';
import 'package:anigmaa/presentation/bloc/user/user_bloc.dart';
import 'package:anigmaa/presentation/bloc/user/user_event.dart';
import 'package:anigmaa/presentation/bloc/user/user_state.dart';
import 'package:anigmaa/presentation/pages/auth/login_screen.dart';
import 'package:anigmaa/injection_container.dart' as di;

import '../helpers/mocks.dart';

// MockBloc dari bloc_test otomatis menggunakan tipe yang benar
class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}

void main() {
  late MockAuthService mockAuthService;
  late MockAuthRemoteDataSource mockAuthDataSource;
  late MockGoogleAuthService mockGoogleAuthService;
  late AuthBloc authBloc;
  late MockUserBloc mockUserBloc;

  // Stub default state untuk MockUserBloc
  void stubUserBloc() {
    when(() => mockUserBloc.state).thenReturn(UserInitial());
    when(() => mockUserBloc.stream).thenAnswer((_) => const Stream.empty());
  }

  setUpAll(() {
    AppLogger().init();
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockAuthDataSource = MockAuthRemoteDataSource();
    mockGoogleAuthService = MockGoogleAuthService();
    mockUserBloc = MockUserBloc();

    authBloc = AuthBloc(mockAuthService, mockAuthDataSource);
    stubUserBloc();

    // LoginScreen mengambil GoogleAuthService dari DI di initState
    if (!di.sl.isRegistered<GoogleAuthService>()) {
      di.sl.registerSingleton<GoogleAuthService>(mockGoogleAuthService);
    }
  });

  tearDown(() async {
    await authBloc.close();
    if (di.sl.isRegistered<GoogleAuthService>()) {
      di.sl.unregister<GoogleAuthService>();
    }
  });

  /// Helper: buat widget tree lengkap untuk LoginScreen
  Widget buildLoginApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<UserBloc>.value(value: mockUserBloc),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('Login Screen UI', () {
    testWidgets('login screen menggunakan key yang benar', (tester) async {
      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      expect(find.byKey(const Key('login_screen')), findsOneWidget);
    });

    testWidgets('menampilkan nama app "flyerr"', (tester) async {
      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      expect(find.text('flyerr'), findsOneWidget);
    });

    testWidgets('menampilkan tombol Google Sign-In', (tester) async {
      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      expect(
        find.byKey(const Key('google_sign_in_button')),
        findsOneWidget,
      );
    });

    testWidgets('tombol Google Sign-In menampilkan teks yang benar',
        (tester) async {
      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      expect(find.text('Lanjut pake Google'), findsOneWidget);
    });

    testWidgets('menampilkan tagline di bawah logo', (tester) async {
      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      expect(
        find.text('Temuin acara seru, bikin kenangan baru 🚀'),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan teks privacy policy', (tester) async {
      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      // Cek ada kata kunci dari privacy text
      expect(
        find.textContaining('Terms of Service'),
        findsOneWidget,
      );
    });
  });

  group('Login Screen Interaksi', () {
    testWidgets('tombol Google Sign-In enabled saat tidak loading',
        (tester) async {
      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('google_sign_in_button')),
      );
      // onPressed tidak null = button aktif
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tap tombol Google Sign-In tidak langsung crash', (tester) async {
      // Mock Google sign-in mengembalikan null (user batal)
      when(() => mockGoogleAuthService.signIn())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      // Tap tombol
      await tester.tap(find.byKey(const Key('google_sign_in_button')));
      await tester.pump();

      // App masih ada (tidak crash)
      expect(find.byKey(const Key('login_screen')), findsOneWidget);
    });

    testWidgets('loading indicator muncul saat login sedang proses',
        (tester) async {
      // Mock: signIn() lambat (tidak selesai selama test)
      when(() => mockGoogleAuthService.signIn()).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(seconds: 30));
          return null;
        },
      );

      await tester.pumpWidget(buildLoginApp());
      await tester.pump();

      // Tap tombol
      await tester.tap(find.byKey(const Key('google_sign_in_button')));
      await tester.pump(); // render frame setelah tap

      // Selama proses login, tombol seharusnya disable
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('google_sign_in_button')),
      );
      expect(button.onPressed, isNull); // disabled
    });
  });
}
