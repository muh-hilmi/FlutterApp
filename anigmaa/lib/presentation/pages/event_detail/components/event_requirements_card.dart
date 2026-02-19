import 'package:flutter/material.dart';
import '../../../../domain/entities/event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventRequirementsCard extends StatelessWidget {
  final Event event;

  const EventRequirementsCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    if (event.requirements == null || event.requirements!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yang Perlu Lo Siapin 📋',
            style: AppTextStyles.bodyLargeBold,
          ),
          const SizedBox(height: 12),
          Text(
            event.requirements!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
