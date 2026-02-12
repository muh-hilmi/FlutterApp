import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../injection_container.dart' as di;
import '../server_unavailable/server_unavailable_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = 'Menyiapkan...';
  final _logger = AppLogger();
  StreamSubscription? _authBlocSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Show splash for at least 1.5 seconds for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authService = di.sl<AuthService>();
    final authBloc = di.sl<AuthBloc>();

    // Check if user has a token stored
    final hasToken = await authService.hasValidToken;

    if (!hasToken) {
      // No token - try Google silent sign-in or go to login
      _tryGoogleSignInOrLogin();
      return;
    }

    // Token exists - validate it via AuthBloc
    setState(() {
      _statusText = 'Mengecek session...';
    });

    // Start validation first, then listen to state changes
    authBloc.validateToken();

    // Listen to AuthBloc state changes
    _authBlocSubscription = authBloc.stream.listen((authState) {
      if (!mounted) return;

      switch (authState.state) {
        case AuthState.validated:
          // Token is valid - navigate to home
          _authBlocSubscription?.cancel();
          Navigator.pushReplacementNamed(context, '/home');
          break;

        case AuthState.unauthenticated:
          // Token is invalid - go to login
          _authBlocSubscription?.cancel();
          _navigateToLogin();
          break;

        case AuthState.serverUnavailable:
          // Server unreachable - show server unavailable screen
          // Don't cancel subscription here - ServerUnavailableScreen will handle navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ServerUnavailableScreen(
                errorMessage: authState.errorMessage,
                retryCount: authState.retryCount,
              ),
            ),
          );
          break;

        case AuthState.offlineMode:
          // Enter offline mode - navigate to home with limited features
          _authBlocSubscription?.cancel();
          Navigator.pushReplacementNamed(context, '/home');
          break;

        case AuthState.validating:
        case AuthState.refreshing:
          // Still validating - update status
          setState(() {
            _statusText = authState.state.description;
          });
          break;

        default:
          break;
      }
    });
  }

  Future<void> _tryGoogleSignInOrLogin() async {
    setState(() {
      _statusText = 'Mengecek akun...';
    });

    try {
      final googleAuthService = di.sl<GoogleAuthService>();
      final googleAccount = await googleAuthService.signInSilently();

      if (googleAccount != null) {
        // Silent sign-in succeeded, authenticate with backend
        setState(() {
          _statusText = 'Login otomatis...';
        });

        final idToken = await googleAuthService.getIdToken();

        if (idToken != null) {
          final authDataSource = di.sl<AuthRemoteDataSource>();
          final authResponse = await authDataSource.loginWithGoogle(idToken);

          final authService = di.sl<AuthService>();
          final authBloc = di.sl<AuthBloc>();

          await authService.saveAuthData(
            userId: authResponse.user.id,
            email: authResponse.user.email ?? '',
            name: authResponse.user.name,
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
          );

          // Notify AuthBloc that token was refreshed
          authBloc.add(AuthTokenRefreshed(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
          ));

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }
    } catch (e) {
      // Silent sign-in failed, this is normal
      _logger.debug('Google silent sign-in failed: $e');
    }

    // NO AUTH: Route based on onboarding status
    if (!mounted) return;

    final authService = di.sl<AuthService>();

    String route;
    if (authService.hasSeenOnboarding) {
      // User has seen onboarding, go to login
      route = '/login';
    } else {
      // First time user, show onboarding
      route = '/onboarding';
    }

    Navigator.pushReplacementNamed(context, route);
  }

  void _navigateToLogin() {
    final authService = di.sl<AuthService>();

    String route;
    if (authService.hasSeenOnboarding) {
      route = '/login';
    } else {
      route = '/onboarding';
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  void dispose() {
    _authBlocSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('splash_screen'),
      backgroundColor: const Color(0xFFFCFCFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFBBC863),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.event,
                color: Color(0xff000000),
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            // App Name
            const Text(
              'flyerr',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF000000),
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cari acara seru di sekitar lo 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF000000),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFBBC863),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status Text
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
