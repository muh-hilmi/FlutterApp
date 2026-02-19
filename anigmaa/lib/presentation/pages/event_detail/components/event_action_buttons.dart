import 'package:flutter/material.dart';
import '../../../../domain/entities/event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventActionButtons extends StatelessWidget {
  final Event event;
  final bool isAttending; // explicit override from screen state
  final VoidCallback onJoinPressed;
  final VoidCallback onManagePressed;
  final VoidCallback onViewTicketPressed;

  const EventActionButtons({
    super.key,
    required this.event,
    required this.isAttending,
    required this.onJoinPressed,
    required this.onManagePressed,
    required this.onViewTicketPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Price or status info on the left
            Expanded(
              child: _buildLeftInfo(),
            ),
            const SizedBox(width: 16),

            // Action button on the right
            Expanded(
              flex: 2,
              child: _buildActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftInfo() {
    if (event.isUserHost) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Host', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          Text('Event kamu', style: AppTextStyles.bodySmall),
        ],
      );
    }

    if (isAttending || event.hasJoined) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Terdaftar', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          Text('Tiket aktif', style: AppTextStyles.bodySmall),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.isFree ? 'Free' : 'Rp ${event.price}',
          style: AppTextStyles.h3.copyWith(color: AppColors.primary),
        ),
        Text(
          event.isFree ? 'Limited spots' : 'per person',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (event.isUserHost) {
      return ElevatedButton(
        onPressed: onManagePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text('Kelola Event', style: AppTextStyles.button),
      );
    }

    if (isAttending || event.hasJoined) {
      return ElevatedButton(
        onPressed: onViewTicketPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          elevation: 0,
        ),
        child: Text('Lihat Tiket', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
      );
    }

    // User hasn't joined — show join/buy button
    final isEnded = event.hasEnded;
    final isFull = event.isFull;
    final label = isEnded
        ? 'Event Selesai'
        : isFull
            ? 'Event Penuh'
            : event.isFree
                ? 'Join Sekarang'
                : 'Beli Tiket';

    return ElevatedButton(
      onPressed: (isEnded || isFull) ? null : onJoinPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.border,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(label, style: AppTextStyles.button),
    );
  }
}
