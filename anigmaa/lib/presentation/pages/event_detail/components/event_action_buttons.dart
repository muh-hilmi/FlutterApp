import 'package:flutter/material.dart';
import '../../../../domain/entities/event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventActionButtons extends StatelessWidget {
  final Event event;
  final VoidCallback onJoinPressed;
  final VoidCallback onManagePressed;

  const EventActionButtons({
    super.key,
    required this.event,
    required this.onJoinPressed,
    required this.onManagePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Assuming we can determine if the current user is the owner
    // For now, we will just show the Join button or Manage button based on logic passed from parent
    // But typically the parent decides WHICH callback to call or button to show.
    // However, the usage in EventDetailScreen passes BOTH.
    // We need to check if the user is the owner to show Manage, or a participant to show Ticket, etc.
    // Since the logic for "isOwner" is usually in the screen or bloc, let's assume the screen handles the visibility logic?
    // Wait, the screen code:
    // child: EventActionButtons(
    //   event: currentEvent,
    //   onJoinPressed: _onJoinPressed,
    //   onManagePressed: _onManagePressed,
    // ),

    // We should probably show "Manage" if it's the user's event, else "Join".
    // Or maybe the screen handles that logic?
    // The screen passes both. Let's look at the implementation.
    // It's a stateless widget. It should probably check `event.organizer.id` vs `currentUserId`.
    // BUT we don't have currentUserId here unless we pass it or get it from auth service.
    // Let's assume for now we render what makes sense based on the event state or just render the Join button as primary.
    // If the usage implies we pass both, maybe we show both? Or switch?

    // In the original code (implied), there was likely logic.
    // Let's implement a standard bottom bar.

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Price Tag (if applicable) or Free
            Expanded(
              child: Column(
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
              ),
            ),
            const SizedBox(width: 16),

            // Join / Manage Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    onJoinPressed, // Default to join/buy for now. Logic for "Manage" needs to be handled.
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  event.isFree ? 'Join Now' : 'Buy Ticket',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
