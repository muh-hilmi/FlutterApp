import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../injection_container.dart' as di;
import '../../../core/auth/auth_bloc.dart'; // Added import
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  late final GoogleAuthService _googleAuthService;

  @override
  void initState() {
    super.initState();
    _googleAuthService = di.sl<GoogleAuthService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('login_screen'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 60),
                _buildGoogleSignInButton(),
                const SizedBox(height: 32),
                _buildPrivacyText(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(Icons.event, color: AppColors.white, size: 50),
        ),
        const SizedBox(height: 24),
        Text(
          'flyerr',
          style: AppTextStyles.display.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Temuin acara seru, bikin kenangan baru 🚀',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('google_sign_in_button'),
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image not found
                      return const Icon(
                        Icons.g_mobiledata,
                        size: 32,
                        color: AppColors.white,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Lanjut pake Google',
                    style: AppTextStyles.bodyLargeBold,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPrivacyText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Dengan lanjut, lo setuju sama Terms of Service dan Privacy Policy kita',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Google
      final googleAccount = await _googleAuthService.signIn();

      if (googleAccount == null) {
        // User cancelled sign in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get Google ID token
      final idToken = await _googleAuthService.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Authenticate with backend using Google token
      final authDataSource = di.sl<AuthRemoteDataSource>();
      final authResponse = await authDataSource.loginWithGoogle(idToken);

      // DEBUG: Log the response from backend
      AppLogger().info(
        'Backend returned user: ${authResponse.user.email} (ID: ${authResponse.user.id})',
      );

      // Save complete auth data using AuthService
      final authService = di.sl<AuthService>();
      await authService.saveAuthData(
        userId: authResponse.user.id,
        email: authResponse.user.email ?? '',
        name: authResponse.user.name,
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // DEBUG: Verify what was saved
      final savedUserId = authService.userId;
      final savedEmail = authService.userEmail;
      AppLogger().info('Saved to storage: $savedEmail (ID: $savedUserId)');

      // Trigger UserBloc to load current user
      if (mounted) {
        context.read<UserBloc>().add(LoadUserProfile());
        // Notify AuthBloc that we have a valid token now
        context.read<AuthBloc>().add(AuthValidateRequested(forceRetry: true));
        AppLogger().info(
          'Triggered UserBloc.LoadUserProfile() and AuthBloc validation',
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Check if this is a new user (account just created)
        // New users have no dateOfBirth AND createdAt is very recent (within last minute)
        final accountAge = DateTime.now().difference(
          authResponse.user.createdAt,
        );
        final isNewUser =
            authResponse.user.dateOfBirth == null && accountAge.inMinutes < 1;

        if (isNewUser) {
          // First-time user - show complete profile screen once
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/complete-profile',
            (route) => false,
          );
        } else {
          // Returning user - go directly to home
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selamat datang kembali, ${googleAccount.displayName ?? 'User'}! 🎉',
              ),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = 'Waduh, gagal login nih';

        // Better error messages
        if (e.toString().contains('timeout') ||
            e.toString().contains('connectTimeout')) {
          errorMessage =
              'Koneksi timeout. Cek ya:\n'
              '1. Koneksi internet lo\n'
              '2. Backend server nyala ga\n'
              '3. API URL udah bener';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Authentication gagal. Coba lagi ya!';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Login endpoint ga ketemu. Cek backend API';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error. Coba lagi nanti ya';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error jaringan. Cek koneksi internet lo dulu';
        } else if (e.toString().contains('PlatformException') ||
            e.toString().contains('channel-error')) {
          errorMessage =
              'Google Sign-In belum dikonfigurasi.\n\n'
              'App ini butuh Google OAuth setup:\n'
              '1. Setup OAuth Client ID di Google Cloud Console\n'
              '2. Tambahin SHA-1 fingerprint\n'
              '3. Enable Google Sign-In API\n\n'
              'Cek GOOGLE_AUTH_SETUP.md buat step-by-step guide';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tutup',
              textColor: AppColors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
