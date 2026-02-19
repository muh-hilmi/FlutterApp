import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DiscoverHeader extends StatelessWidget {
  final String location;
  final VoidCallback onRefreshLocation;
  final VoidCallback onToggleView;
  final bool isMapView;

  const DiscoverHeader({
    super.key,
    required this.location,
    required this.onRefreshLocation,
    required this.onToggleView,
    required this.isMapView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title Icon (Brand Color Box)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Discover',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              // Map/List Toggle (Glassmorphism look)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isMapView ? Icons.list_rounded : Icons.map_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  onPressed: onToggleView,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location Row (Constrained Width)
          IntrinsicWidth(
            child: GestureDetector(
              onTap: onRefreshLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        location,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
