import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Centralized SnackBar helper for consistent error/success/warning notifications
///
/// Design: Clean white background + colored icon + accent border
/// Warm, minimal style inspired by profile page
class SnackBarHelper {
  SnackBarHelper._();

  static const Duration _defaultDuration = Duration(seconds: 4);

  /// Show error notification
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      iconColor: AppColors.error,
      icon: Icons.error_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show success notification
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      iconColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show warning notification
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      iconColor: AppColors.orange,
      icon: Icons.warning_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show info notification
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      iconColor: AppColors.info,
      icon: Icons.info_rounded,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color iconColor,
    required IconData icon,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon with soft background
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Message text
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: iconColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.secondary,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show custom notification
  static void showCustom(
    BuildContext context, {
    required Widget content,
    required Color borderColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: AppColors.white,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        action: action,
      ),
    );
  }
}
