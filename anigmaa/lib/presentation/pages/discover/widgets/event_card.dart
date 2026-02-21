import 'package:anigmaa/domain/entities/event_category.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/event.dart';
import '../../../../core/utils/app_logger.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Debug: Log image URLs
    if (event.imageUrls.isNotEmpty) {
      AppLogger().info(
        'Event "${event.title}" has ${event.imageUrls.length} image(s)',
      );
      AppLogger().info('First image URL: ${event.imageUrls.first}');
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            AspectRatio(
              aspectRatio: 1.3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: event.fullImageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: event.fullImageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFBBC863),
                                ),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          AppLogger().error(
                            'Failed to load image for "${event.title}"',
                          );
                          AppLogger().error('URL: $url');
                          AppLogger().error('Error: $error');
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Date Header (Darker for legibility)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 12,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventDate(event.startTime).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 2. Title
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 3. Compact Location & Metrics
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: const Color(0xFFBBC863),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                event.location.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Interests & Joined
                      Row(
                        children: [
                          const Text('📌', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 2),
                          Text(
                            '${event.interestedCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textEmphasis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.people_alt_rounded,
                            size: 12,
                            color: Colors.blue[400],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${event.currentAttendees}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textEmphasis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.textTertiary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 10),
                  // 4. Category & Price Row (Moved to bottom)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFBBC863,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category.displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black, // Darker version of accent
                          ),
                        ),
                      ),
                      Text(
                        _formatPrice(event.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
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

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFBBC863)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.event, color: Colors.black, size: 40)],
        ),
      ),
    );
  }

  String _formatPrice(double? price) {
    if (price == null || price == 0) return 'Free';
    if (price >= 1000000) {
      return 'Rp${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return 'Rp${(price / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp$price';
  }

  String _formatEventDate(DateTime dateTime) {
    return DateFormat('d MMM • HH:mm').format(dateTime.toLocal());
  }
}
