import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../data/models/user_model.dart';
import '../../../injection_container.dart' as di;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = 'Menyiapkan...';
  final _logger = AppLogger();

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

    // STEP 1: Check if refresh token exists locally
    setState(() {
      _statusText = 'Memeriksa session...';
    });

    final hasRefreshToken = await authService.hasRefreshToken;

    if (!hasRefreshToken) {
      // No token at all - go to login/onboarding
      _logger.info('[Splash] No refresh token found');
      _navigateToLogin();
      return;
    }

    // STEP 2: Check if access token is still valid (skip backend call)
    _logger.info('[Splash] Refresh token found, checking access token expiry...');

    final isAccessTokenExpired = await authService.isAccessTokenExpired();

    if (!isAccessTokenExpired) {
      // Access token is still valid - skip backend call entirely
      _logger.info('[Splash] Access token still valid, skipping backend refresh');

      // Check profile completion using cached data
      final needsProfileCompletion = await _needsProfileCompletion();

      if (!mounted) return;

      if (needsProfileCompletion) {
        Navigator.pushReplacementNamed(context, '/complete-profile');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    // STEP 3: Access token is expired - try to refresh it (with timeout)
    _logger.info('[Splash] Access token expired, attempting refresh...');

    setState(() {
      _statusText = 'Memperbarui session...';
    });

    try {
      final authDataSource = di.sl<AuthRemoteDataSource>();
      final storedRefreshToken = await authService.refreshToken;

      if (storedRefreshToken == null) {
        // Shouldn't happen, but handle gracefully
        _logger.warning('[Splash] Refresh token null after check');
        _navigateToLogin();
        return;
      }

      // Try to refresh token via backend (5 second timeout)
      final authResponse = await authDataSource.refreshToken(storedRefreshToken).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Refresh token timeout');
        },
      );

      // STEP 4: Refresh success - save new tokens and go to home
      _logger.info('[Splash] Token refresh successful');
      await authService.updateTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Update user data if changed
      if (authResponse.user.id.isNotEmpty) {
        await authService.setUserId(authResponse.user.id);
        await authService.setUserEmail(authResponse.user.email ?? '');
        await authService.setUserName(authResponse.user.name);
      }

      // Check profile completion and navigate
      _checkProfileCompletionAndNavigate(authResponse.user);

    } catch (e) {
      // STEP 5: Refresh failed - check if it's network error or invalid token
      _logger.warning('[Splash] Token refresh failed: $e');

      final errorMsg = e.toString().toLowerCase();

      // Is this a network/timeout error (not auth failure)?
      final isNetworkError = errorMsg.contains('timeout') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('network') ||
          errorMsg.contains('socket');

      if (isNetworkError) {
        // Network error - BUT user has refresh token locally
        // Allow offline access to Home (Instagram/TikTok style)
        _logger.info('[Splash] Network error but token exists - allowing offline access');
        _navigateToHomeOffline();
      } else {
        // Auth error (401/403) - token is actually invalid
        _logger.info('[Splash] Token invalid - clearing and going to login');
        await authService.clearAuthData();
        _navigateToLogin();
      }
    }
  }


  Future<bool> _needsProfileCompletion() async {
    // Check cached user data for profile completion
    // We use SharedPreferences data since we're skipping backend call
    final authService = di.sl<AuthService>();

    // For now, assume profile is complete if we have user data
    // In production, you might store profile completion status separately
    final userId = authService.userId;

    // If we don't have user ID stored, assume profile not complete
    if (userId == null || userId.isEmpty) {
      return true;
    }

    // TODO: Store and check profile completion flag
    // For now, return false to avoid forcing profile completion on cached data
    return false;
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

  Future<void> _checkProfileCompletionAndNavigate(UserModel user) async {
    if (!mounted) return;

    // Check if user has completed essential profile fields
    final needsProfileCompletion =
        user.dateOfBirth == null ||
        user.location == null ||
        user.location!.isEmpty;

    if (needsProfileCompletion) {
      Navigator.pushReplacementNamed(context, '/complete-profile');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _navigateToHomeOffline() {
    // Navigate to home with cached/offline data (Instagram/TikTok style)
    _logger.info('[Splash] Entering offline mode with cached data');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('splash_screen'),
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.event,
                color: AppColors.primary,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            // App Name
            Text(
              'flyerr',
              style: AppTextStyles.h1.copyWith(
                letterSpacing: -1.0,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cari acara seru di sekitar lo 🎉',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status Text
            Text(
              _statusText,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
