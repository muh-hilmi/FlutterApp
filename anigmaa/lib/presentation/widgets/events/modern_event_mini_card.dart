import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ModernEventMiniCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onJoin;
  final VoidCallback? onFindMatches;

  const ModernEventMiniCard({
    super.key,
    required this.event,
    this.onJoin,
    this.onFindMatches,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsBloc, EventsState>(
      buildWhen: (previous, current) {
        // Rebuild if the specific event's interest data has changed
        if (current is EventsLoaded && previous is EventsLoaded) {
          try {
            final prevEvent = previous.events.firstWhere(
              (e) => e.id == event.id,
            );
            final currEvent = current.events.firstWhere(
              (e) => e.id == event.id,
            );
            // Compare relevant fields, not just object reference
            return prevEvent.interestedCount != currEvent.interestedCount ||
                prevEvent.isInterested != currEvent.isInterested;
          } catch (_) {
            // Event not found in state - rebuild to try again
            return true;
          }
        }
        // State type changed - rebuild
        return current is EventsLoaded;
      },
      builder: (context, state) {
        // CRITICAL: ALWAYS get displayEvent from BlocState first
        // Only use widget.event as absolute fallback
        Event displayEvent = event;
        if (state is EventsLoaded) {
          try {
            displayEvent = state.events.firstWhere((e) => e.id == event.id);
            // Found in Bloc state - this is the TRUTH
          } catch (_) {
            // Event NOT in Bloc state - this is the BUG source!
            // Use widget.event BUT trigger state update for next build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final bloc = context.read<EventsBloc>();
              bloc.add(EnsureEventInState(event));
            });
            displayEvent = event;
          }
        }

        final bool isEnded =
            displayEvent.status == EventStatus.ended || displayEvent.hasEnded;

        return GestureDetector(
          onDoubleTap: () {
            // Double-tap = LIKE ONLY (TikTok/Instagram style)
            // Idempotent: if already interested, does nothing
            context.read<EventsBloc>().add(LikeInterestRequested(displayEvent));
          },
          child: Container(
            decoration: BoxDecoration(
              color: isEnded
                  ? AppColors.surface
                  : AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnded
                    ? AppColors.border
                    : AppColors.secondary,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title with Status Badge and Interested Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayEvent.title,
                        style: AppTextStyles.bodyLargeBold.copyWith(
                          letterSpacing: -0.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (isEnded) ...[
                      const SizedBox(width: 4),
                      _buildStatusBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Info Row - Time
                _buildInfoRow(
                  Icons.access_time_rounded,
                  _formatEventDateTime(displayEvent),
                  isEnded,
                ),
                const SizedBox(height: 8),

                // Info Row - Location
                _buildInfoRow(
                  Icons.location_on_rounded,
                  displayEvent.location.name,
                  isEnded,
                ),
                const SizedBox(height: 14),

                // Bottom Row - Participants & Price
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isEnded
                                ? '${displayEvent.currentAttendees} attended'
                                : '${displayEvent.currentAttendees} joined',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Interested Count - Tappable for LIKE ONLY (Instagram style)
                    // Card cannot unlike - use Detail page for toggle
                    GestureDetector(
                      onTap: () {
                        // Pin tap on Card = LIKE ONLY (same as double-tap)
                        // Idempotent: if already interested, does nothing
                        context.read<EventsBloc>().add(
                          LikeInterestRequested(displayEvent),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: displayEvent.isInterested
                              ? AppColors.secondary.withValues(alpha: 0.2)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: displayEvent.isInterested
                                ? AppColors.secondary
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: displayEvent.isInterested ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.elasticOut,
                              child: Text(
                                displayEvent.isInterested ? '📌' : '📍',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${displayEvent.interestedCount}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: displayEvent.isInterested
                                    ? const Color(0xFF556018)
                                    : AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Price Badge (only for upcoming)
                    if (!isEnded) _buildPriceBadge(displayEvent),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isEnded) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✓',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'SELESAI',
            style: AppTextStyles.label.copyWith(
              fontSize: 10,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge(Event event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: event.isFree ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        event.isFree ? 'Gratis' : _formatPrice(event.price ?? 0),
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  String _formatEventDateTime(Event event) {
    final now = DateTime.now();
    final localStartTime = event.startTime.toLocal();
    // Use local time for difference calculation to get correct relative time
    final diff = localStartTime.difference(now);

    const daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const monthsShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    // Check if event has ended - use local time for day/month
    if (event.hasEnded) {
      return 'Sudah selesai · ${daysShort[localStartTime.weekday - 1]}, ${localStartTime.day} ${monthsShort[localStartTime.month - 1]}';
    }

    // Format waktu relatif yang mudah dipahami
    if (diff.inMinutes < 60 && diff.inMinutes >= 0) {
      if (diff.inMinutes < 1) {
        return 'Dimulai sekarang! 🔥';
      } else if (diff.inMinutes <= 30) {
        return '${diff.inMinutes} menit lagi! ⚡';
      } else {
        return '${diff.inMinutes} menit lagi';
      }
    } else if (diff.inHours < 24 && diff.inHours >= 0) {
      return '${diff.inHours} jam lagi! 🔥';
    } else if (diff.inDays == 0) {
      return 'Hari ini · ${localStartTime.hour}:${localStartTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Besok · ${localStartTime.hour}:${localStartTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lagi! · ${daysShort[localStartTime.weekday - 1]}, ${localStartTime.day} ${monthsShort[localStartTime.month - 1]}';
    } else {
      return '${daysShort[localStartTime.weekday - 1]}, ${localStartTime.day} ${monthsShort[localStartTime.month - 1]} · ${localStartTime.hour}:${localStartTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      // Format in millions (jt)
      double millions = price / 1000000;
      if (millions % 1 == 0) {
        return '${millions.toInt()}jt';
      } else {
        return '${millions.toStringAsFixed(1)}jt';
      }
    } else if (price >= 1000) {
      // Format in thousands (k)
      double thousands = price / 1000;
      if (thousands % 1 == 0) {
        return '${thousands.toInt()}k';
      } else {
        return '${thousands.toStringAsFixed(1)}k';
      }
    } else {
      return price.toInt().toString();
    }
  }
}
