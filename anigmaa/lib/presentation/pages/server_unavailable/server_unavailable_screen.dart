import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/errors/error_messages.dart';
import '../../../injection_container.dart' as di;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Screen shown when server is unreachable but user has a valid token
///
/// Features:
/// - Shows clear error message with proper error classification
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
            Navigator.pushReplacementNamed(context, '/home');
            break;

          case AuthState.offlineMode:
            Navigator.pushReplacementNamed(context, '/home');
            break;

          case AuthState.unauthenticated:
            Navigator.pushReplacementNamed(context, '/login');
            break;

          case AuthState.serverUnavailable:
          case AuthState.validating:
          case AuthState.refreshing:
          case AuthState.error:
          case AuthState.initial:
            break;
        }
      },
      child: BlocBuilder<AuthBloc, AuthStateData>(
        bloc: authBloc,
        builder: (context, state) {
          // Use error message from state, parameter, or default
          final displayMessage = state.errorMessage ??
              errorMessage ??
              ErrorMessageResolver.genericNetworkError;

          // Get appropriate title based on error message
          final errorTitle = ErrorMessageResolver.getTitle(displayMessage);

          return Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with design system colors
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForError(displayMessage),
                        size: 40,
                        color: AppColors.secondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      errorTitle,
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Message
                    Text(
                      displayMessage,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
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
                        'Memeriksa koneksi...',
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
                        onPressed: _isBusy(state)
                            ? null
                            : () {
                                authBloc.add(AuthRetryValidation());
                              },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.border,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Continue offline button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isBusy(state)
                            ? null
                            : () {
                                authBloc.add(AuthEnterOfflineMode());
                              },
                        icon: const Icon(Icons.wifi_off_rounded, size: 20),
                        label: const Text('Lanjut Offline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Force logout text button
                    TextButton.icon(
                      onPressed: _isBusy(state)
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Keluar'),
                                  content: const Text(
                                    'Kamu akan keluar dari akun. Data lokal akan tetap tersimpan.',
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
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: Text(
                        'Keluar dari Akun',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _isBusy(state)
                              ? AppColors.border
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Auto-retry indicator
                    if (state.retryCount > 0 && !_isBusy(state))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textTertiary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mencoba ulang otomatis...',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
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

  bool _isBusy(AuthStateData state) {
    return state.state == AuthState.validating ||
        state.state == AuthState.refreshing;
  }

  IconData _getIconForError(String message) {
    final msgLower = message.toLowerCase();

    if (msgLower.contains('internet') || msgLower.contains('koneksi')) {
      return Icons.wifi_off_rounded;
    }
    if (msgLower.contains('server')) {
      return Icons.cloud_off_rounded;
    }
    if (msgLower.contains('sesi') || msgLower.contains('login')) {
      return Icons.lock_clock_rounded;
    }
    if (msgLower.contains('izin') || msgLower.contains('akses')) {
      return Icons.block_rounded;
    }

    return Icons.error_outline_rounded;
  }
}
