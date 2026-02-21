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
  final VoidCallback? onInterestPressed;

  const EventActionButtons({
    super.key,
    required this.event,
    required this.isAttending,
    required this.onJoinPressed,
    required this.onManagePressed,
    required this.onViewTicketPressed,
    this.onInterestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Price or status info on the left
              Expanded(child: _buildLeftInfo()),
              // Action button
              Expanded(flex: 2, child: _buildActionButton()),
              // Interest pin button on the right (hidden for host)
              if (!event.isUserHost) const SizedBox(width: 12),
              if (!event.isUserHost) _buildInterestButton(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double? price) {
    if (price == null || price == 0) return 'Free';
    if (price >= 1000) {
      return 'Rp${(price / 1000).toStringAsFixed(0)}k';
    }
    return 'Rp${price.toStringAsFixed(0)}';
  }

  Widget _buildLeftInfo() {
    if (event.isUserHost) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Host',
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
          Text('Event kamu', style: AppTextStyles.bodySmall),
        ],
      );
    }

    if (isAttending || event.hasJoined) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terdaftar',
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
          Text('Tiket aktif', style: AppTextStyles.bodySmall),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatPrice(event.price),
          style: AppTextStyles.h3.copyWith(color: AppColors.primary),
        ),
        Text(
          event.isFree ? 'Terbatas!' : 'per orang',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInterestButton() {
    final isInterested = event.isInterested;
    final count = event.interestedCount;

    return GestureDetector(
      onTap: onInterestPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isInterested
                  ? AppColors.secondary.withValues(alpha: 0.15)
                  : AppColors.surfaceAlt,
              shape: BoxShape.circle,
              border: isInterested
                  ? Border.all(color: AppColors.secondary, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '📌',
                style: TextStyle(fontSize: isInterested ? 22 : 18),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            count > 0 ? '$count' : 'Pin',
            style: AppTextStyles.caption.copyWith(
              color: isInterested
                  ? AppColors.secondary
                  : AppColors.textTertiary,
              fontWeight: isInterested ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        child: Text(
          'Lihat Tiket',
          style: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
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
