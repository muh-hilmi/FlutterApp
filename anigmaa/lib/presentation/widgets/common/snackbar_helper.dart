import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Centralized SnackBar helper for consistent error/success/warning notifications
///
/// All snackbars shown through this helper will:
/// - Auto-dismiss after 5 seconds
/// - Use consistent styling from AppColors
/// - Support optional action buttons
/// - Use floating behavior for modern look
class SnackBarHelper {
  SnackBarHelper._();

  static const Duration _defaultDuration = Duration(seconds: 5);

  /// Show error notification (auto-dismisses after 5 seconds)
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show success notification (auto-dismisses after 5 seconds)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show warning notification (auto-dismisses after 5 seconds)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFF111111))),
        backgroundColor: AppColors.warning,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: const Color(0xFF111111),
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show info notification (auto-dismisses after 5 seconds)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }

  /// Show custom notification (auto-dismisses after 5 seconds)
  static void showCustom(
    BuildContext context, {
    required Widget content,
    required Color backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: backgroundColor,
        duration: duration ?? _defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: action,
      ),
    );
  }
}
