import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/auth_state.dart';
import '../../../injection_container.dart' as di;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Screen shown when server is unreachable but user has a valid token
///
/// Features:
/// - Shows clear error message
/// - Retry button (triggers re-validation)
/// - Continue offline button (enters offline mode)
/// - Force logout button (clears local state)
class ServerUnavailableScreen extends StatelessWidget {
  final String? errorMessage;
  final int retryCount;

  const ServerUnavailableScreen({
    super.key,
    this.errorMessage,
    this.retryCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final authBloc = di.sl<AuthBloc>();

    return BlocListener<AuthBloc, AuthStateData>(
      bloc: authBloc,
      listener: (context, state) {
        if (!context.mounted) return;

        switch (state.state) {
          case AuthState.validated:
            // Token is valid - navigate to home
            Navigator.pushReplacementNamed(context, '/home');
            break;

          case AuthState.offlineMode:
            // Enter offline mode - navigate to home
            Navigator.pushReplacementNamed(context, '/home');
            break;

          case AuthState.unauthenticated:
            // Token is invalid - go to login
            Navigator.pushReplacementNamed(context, '/login');
            break;

          case AuthState.serverUnavailable:
          case AuthState.validating:
          case AuthState.refreshing:
          case AuthState.error:
          case AuthState.initial:
            // Stay on this screen
            break;
        }
      },
      child: BlocBuilder<AuthBloc, AuthStateData>(
        bloc: authBloc,
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off,
                        size: 40,
                        color: Color(0xFFFFA726),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Server Tidak Dapat Dihubungi',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Message
                    Text(
                      state.errorMessage ??
                          errorMessage ??
                          'Tidak dapat terhubung ke server. Periksa koneksi internet kamu.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Show loading if validating
                    if (state.state == AuthState.validating ||
                        state.state == AuthState.refreshing) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.state.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Retry button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state.state == AuthState.validating ||
                                state.state == AuthState.refreshing
                            ? null
                            : () {
                                authBloc.add(AuthRetryValidation());
                              },
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.border,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Continue offline button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.state == AuthState.validating ||
                                state.state == AuthState.refreshing
                            ? null
                            : () {
                                authBloc.add(AuthEnterOfflineMode());
                              },
                        icon: const Icon(Icons.wifi_off, size: 20),
                        label: const Text('Lanjut Offline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Force logout text button
                    TextButton.icon(
                      onPressed: state.state == AuthState.validating ||
                              state.state == AuthState.refreshing
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Keluar?'),
                                  content: const Text(
                                    'Kamu akan keluar dari aplikasi. Data offline akan tetap tersimpan.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Keluar'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && context.mounted) {
                                authBloc.add(AuthLogoutRequested());
                              }
                            },
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(
                        'Keluar dari akun',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: state.state == AuthState.validating ||
                                  state.state == AuthState.refreshing
                              ? AppColors.border
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Retry count indicator
                    if (state.retryCount > 0)
                      Text(
                        'Percobaan otomatis akan dilakukan sebentar lagi...',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
