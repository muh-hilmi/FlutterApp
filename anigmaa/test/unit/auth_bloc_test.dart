/// ============================================================
/// AUTH BLOC UNIT TESTS
/// ============================================================
///
/// Test ini menguji semua kemungkinan perubahan state di AuthBloc.
/// Tidak perlu emulator — jalankan dengan:
///
///   flutter test test/unit/auth_bloc_test.dart
///
/// Setiap `blocTest` memiliki 3 bagian:
///   - `build`  → buat bloc dengan mock yang disiapkan
///   - `act`    → kirim event ke bloc
///   - `expect` → state apa yang harus keluar
/// ============================================================

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anigmaa/core/auth/auth_bloc.dart';
import 'package:anigmaa/core/auth/auth_state.dart';
import 'package:anigmaa/core/utils/app_logger.dart';

import '../helpers/mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockAuthRemoteDataSource mockAuthDataSource;

  // Inisialisasi AppLogger sekali sebelum semua test
  setUpAll(() {
    AppLogger().init();
  });

  // Setup dijalankan sebelum SETIAP test
  setUp(() {
    mockAuthService = MockAuthService();
    mockAuthDataSource = MockAuthRemoteDataSource();
  });

  // ─── Helper: buat AuthBloc baru ────────────────────────────────────────────
  AuthBloc buildBloc() => AuthBloc(mockAuthService, mockAuthDataSource);

  // ─── Test Group 1: Initial State ───────────────────────────────────────────
  group('Initial State', () {
    test('state awal adalah AuthState.initial', () {
      final bloc = buildBloc();
      expect(bloc.state.state, equals(AuthState.initial));
      expect(bloc.state.retryCount, equals(0));
      expect(bloc.state.errorMessage, isNull);
      bloc.close();
    });

    test('isAuthenticated = false saat initial', () {
      final bloc = buildBloc();
      expect(bloc.isAuthenticated, isFalse);
      bloc.close();
    });
  });

  // ─── Test Group 2: Validate Token — No Token ───────────────────────────────
  group('AuthValidateRequested — tidak ada token', () {
    blocTest<AuthBloc, AuthStateData>(
      'emit unauthenticated ketika tidak ada token tersimpan',
      build: () {
        // Simulasi: tidak ada access token di storage
        when(() => mockAuthService.hasValidToken)
            .thenAnswer((_) async => false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthValidateRequested()),
      expect: () => [
        isA<AuthStateData>().having(
          (s) => s.state,
          'auth state',
          AuthState.unauthenticated,
        ),
      ],
    );
  });

  // ─── Test Group 3: Validate Token — Token Valid ────────────────────────────
  group('AuthValidateRequested — token valid', () {
    blocTest<AuthBloc, AuthStateData>(
      'emit validating lalu validated ketika API berhasil',
      build: () {
        when(() => mockAuthService.hasValidToken)
            .thenAnswer((_) async => true);
        // Simulasi: API mengembalikan user yang valid
        when(() => mockAuthDataSource.getCurrentUser())
            .thenAnswer((_) async => fakeCompleteUser());
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthValidateRequested()),
      expect: () => [
        // State 1: sedang validasi
        isA<AuthStateData>().having(
          (s) => s.state,
          'validating state',
          AuthState.validating,
        ),
        // State 2: validasi berhasil
        isA<AuthStateData>().having(
          (s) => s.state,
          'validated state',
          AuthState.validated,
        ),
      ],
    );

    blocTest<AuthBloc, AuthStateData>(
      'validatedAt diisi ketika token valid',
      build: () {
        when(() => mockAuthService.hasValidToken)
            .thenAnswer((_) async => true);
        when(() => mockAuthDataSource.getCurrentUser())
            .thenAnswer((_) async => fakeCompleteUser());
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthValidateRequested()),
      verify: (bloc) {
        expect(bloc.state.validatedAt, isNotNull);
        expect(bloc.state.retryCount, equals(0));
      },
    );
  });

  // ─── Test Group 4: Validate Token — Token Expired (401) ───────────────────
  group('AuthValidateRequested — token tidak valid', () {
    blocTest<AuthBloc, AuthStateData>(
      'emit unauthenticated ketika API return 401',
      build: () {
        when(() => mockAuthService.hasValidToken)
            .thenAnswer((_) async => true);
        // Simulasi: API mengembalikan error 401 Unauthorized
        when(() => mockAuthDataSource.getCurrentUser())
            .thenThrow(Exception('401 unauthorized'));
        // Simulasi: clearAuthData berhasil
        when(() => mockAuthService.clearAuthData())
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthValidateRequested()),
      expect: () => [
        isA<AuthStateData>().having(
          (s) => s.state,
          'validating',
          AuthState.validating,
        ),
        isA<AuthStateData>().having(
          (s) => s.state,
          'unauthenticated after 401',
          AuthState.unauthenticated,
        ),
      ],
    );

    blocTest<AuthBloc, AuthStateData>(
      'emit unauthenticated ketika API return 403',
      build: () {
        when(() => mockAuthService.hasValidToken)
            .thenAnswer((_) async => true);
        when(() => mockAuthDataSource.getCurrentUser())
            .thenThrow(Exception('403 forbidden invalid token'));
        when(() => mockAuthService.clearAuthData())
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthValidateRequested()),
      expect: () => [
        isA<AuthStateData>().having((s) => s.state, '', AuthState.validating),
        isA<AuthStateData>().having(
            (s) => s.state, '', AuthState.unauthenticated),
      ],
    );
  });

  // ─── Test Group 5: Validate Token — Network Error ─────────────────────────
  group('AuthValidateRequested — network error', () {
    blocTest<AuthBloc, AuthStateData>(
      'emit serverUnavailable ketika koneksi timeout',
      build: () {
        when(() => mockAuthService.hasValidToken)
            .thenAnswer((_) async => true);
        // Simulasi: timeout — backend tidak bisa diakses
        when(() => mockAuthDataSource.getCurrentUser())
            .thenThrow(TimeoutException('Connection timeout'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthValidateRequested()),
      expect: () => [
        isA<AuthStateData>().having((s) => s.state, '', AuthState.validating),
        isA<AuthStateData>().having(
          (s) => s.state,
          'server unavailable after timeout',
          AuthState.serverUnavailable,
        ),
      ],
    );

    blocTest<AuthBloc, AuthStateData>(
      'retryCount bertambah setiap network error',
      build: () {
        when(() => mockAuthService.hasValidToken)
            .thenAnswer((_) async => true);
        when(() => mockAuthDataSource.getCurrentUser())
            .thenThrow(Exception('connection refused'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthValidateRequested()),
      verify: (bloc) {
        expect(bloc.state.retryCount, equals(1));
      },
    );
  });

  // ─── Test Group 6: Token Refresh ───────────────────────────────────────────
  group('AuthTokenRefreshed', () {
    blocTest<AuthBloc, AuthStateData>(
      'emit validated ketika token berhasil direfresh',
      build: () {
        when(() => mockAuthService.updateTokens(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
            )).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthTokenRefreshed(
        accessToken: 'new-access-token-xyz',
        refreshToken: 'new-refresh-token-xyz',
      )),
      expect: () => [
        isA<AuthStateData>().having(
          (s) => s.state,
          'validated after token refresh',
          AuthState.validated,
        ),
      ],
    );

    blocTest<AuthBloc, AuthStateData>(
      'emit validated dengan hanya accessToken (tanpa refreshToken)',
      build: () {
        when(() => mockAuthService.setAccessToken(any()))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthTokenRefreshed(
        accessToken: 'new-access-token',
        // refreshToken = null → hanya update access token
      )),
      expect: () => [
        isA<AuthStateData>().having((s) => s.state, '', AuthState.validated),
      ],
    );
  });

  // ─── Test Group 7: Logout ──────────────────────────────────────────────────
  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthStateData>(
      'emit unauthenticated dan clear data setelah logout',
      build: () {
        when(() => mockAuthService.clearAuthData())
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        isA<AuthStateData>().having(
          (s) => s.state,
          'unauthenticated after logout',
          AuthState.unauthenticated,
        ),
      ],
      verify: (bloc) {
        // Pastikan clearAuthData dipanggil sekali
        verify(() => mockAuthService.clearAuthData()).called(1);
      },
    );
  });

  // ─── Test Group 8: Offline Mode ────────────────────────────────────────────
  group('AuthEnterOfflineMode', () {
    blocTest<AuthBloc, AuthStateData>(
      'emit offlineMode ketika user pilih offline',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(AuthEnterOfflineMode()),
      expect: () => [
        isA<AuthStateData>().having(
          (s) => s.state,
          'offline mode',
          AuthState.offlineMode,
        ),
      ],
    );

    test('isAuthenticated = true saat offlineMode', () {
      // offlineMode = user masih bisa akses app
      expect(AuthState.offlineMode.isAuthenticated, isTrue);
    });
  });

  // ─── Test Group 9: State Helper Methods ────────────────────────────────────
  group('AuthState helper methods', () {
    test('validated.isAuthenticated = true', () {
      expect(AuthState.validated.isAuthenticated, isTrue);
    });

    test('unauthenticated.isAuthenticated = false', () {
      expect(AuthState.unauthenticated.isAuthenticated, isFalse);
    });

    test('validating.isLoading = true', () {
      expect(AuthState.validating.isLoading, isTrue);
    });

    test('refreshing.isLoading = true', () {
      expect(AuthState.refreshing.isLoading, isTrue);
    });

    test('unauthenticated.shouldShowLogin = true', () {
      expect(AuthState.unauthenticated.shouldShowLogin, isTrue);
    });

    test('validated.shouldShowLogin = false', () {
      expect(AuthState.validated.shouldShowLogin, isFalse);
    });
  });

  // ─── Test Group 10: AuthStateData ─────────────────────────────────────────
  group('AuthStateData', () {
    test('isRecentlyValidated = false ketika belum pernah validated', () {
      const state = AuthStateData(state: AuthState.initial);
      expect(state.isRecentlyValidated, isFalse);
    });

    test('isRecentlyValidated = true ketika baru saja validated', () {
      final state = AuthStateData(
        state: AuthState.validated,
        validatedAt: DateTime.now(),
      );
      expect(state.isRecentlyValidated, isTrue);
    });

    test('isRecentlyValidated = false ketika validated > 5 menit lalu', () {
      final state = AuthStateData(
        state: AuthState.validated,
        validatedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(state.isRecentlyValidated, isFalse);
    });

    test('copyWith mempertahankan nilai lama kalau tidak diisi', () {
      const original = AuthStateData(
        state: AuthState.validating,
        retryCount: 2,
        errorMessage: 'test error',
      );
      final copy = original.copyWith(state: AuthState.validated);
      expect(copy.retryCount, equals(2));
      expect(copy.errorMessage, equals('test error'));
      expect(copy.state, equals(AuthState.validated));
    });
  });
}
