import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Non-intrusive offline banner that shows at the top of the screen
///
/// Features:
/// - Auto-shows when offline
/// - Auto-hides when online
/// - Non-blocking (doesn't prevent interaction)
/// - Uses design system colors
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityService(),
      builder: (context, child) {
        final connectivityService = ConnectivityService();

        if (connectivityService.isOnline) {
          // Online - don't show banner
          return const SizedBox.shrink();
        }

        // Offline - show banner
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Warning icon
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),

              // Message
              Expanded(
                child: Text(
                  'Offline — menampilkan data terakhir',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Refresh icon (optional - can be used for manual refresh)
              Icon(
                Icons.more_horiz,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Sliver variant for use in CustomScrollView
class OfflineBannerSliver extends StatelessWidget {
  const OfflineBannerSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: const OfflineBanner(),
    );
  }
}
