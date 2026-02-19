import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/event.dart';
import '../../../../core/constants/app_colors.dart' as legacyColors;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/event_category_utils.dart';
import '../../../bloc/events/events_bloc.dart';
import '../../../bloc/events/events_state.dart';
import '../event_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventSimilarList extends StatelessWidget {
  final Event currentEvent;

  const EventSimilarList({super.key, required this.currentEvent});

  @override
  Widget build(BuildContext context) {
    final similarEvents = _getSimilarEvents(context);

    if (similarEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Similar Events',
            style: AppTextStyles.bodyLargeBold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: similarEvents.length,
            itemBuilder: (context, index) {
              return _buildSimilarEventCard(context, similarEvents[index]);
            },
          ),
        ),
      ],
    );
  }

  List<Event> _getSimilarEvents(BuildContext context) {
    final eventsState = context.read<EventsBloc>().state;
    if (eventsState is! EventsLoaded) {
      return [];
    }

    final allEvents = eventsState.events;
    final similarEvents = allEvents
        .where(
          (event) =>
              event.id != currentEvent.id && // Exclude current event
              event.category == currentEvent.category,
        ) // Same category
        .take(3)
        .toList();

    // If not enough events from same category, fill with random events
    if (similarEvents.length < 3) {
      final otherEvents = allEvents
          .where(
            (event) =>
                event.id != currentEvent.id && !similarEvents.contains(event),
          )
          .take(3 - similarEvents.length)
          .toList();
      similarEvents.addAll(otherEvents);
    }

    return similarEvents;
  }

  Widget _buildSimilarEventCard(BuildContext context, Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    event.fullImageUrls.isNotEmpty
                        ? event.fullImageUrls.first
                        : 'https://doodleipsum.com/600x400/abstract',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: legacyColors.AppColors.getCategoryColor(event.category),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        EventCategoryUtils.getCategoryName(event.category),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Event details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.name,
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${event.currentAttendees}/${event.maxAttendees}',
                        style: AppTextStyles.captionSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
