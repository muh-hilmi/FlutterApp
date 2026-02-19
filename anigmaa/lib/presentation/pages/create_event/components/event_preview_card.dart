import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../../domain/entities/event_category.dart';
import '../../../../core/utils/event_category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventPreviewCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime startDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String locationName;
  final EventCategory category;
  final bool isFree;
  final double price;
  final int capacity;
  // V2: Private Events - TODO: Re-enable for V2
  // final EventPrivacy privacy;
  final File? coverImage;
  final VoidCallback? onTap;

  const EventPreviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.category,
    required this.isFree,
    required this.price,
    required this.capacity,
    // V2: Private Events - TODO: Re-enable for V2
    // required this.privacy,
    this.coverImage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with gradient overlay
            if (coverImage != null)
              Stack(
                children: [
                  Image.file(
                    coverImage!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                            AppColors.secondary.withValues(alpha: 0.3),
                            AppColors.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.event,
                          size: 64,
                          color: AppColors.secondary,
                        ),
                      ),
                    );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Preview badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.preview,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PREVIEW',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.secondary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              // Default gradient header when no image
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.3),
                      AppColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.event,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                ),
              ),

            // Content padding
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      EventCategoryUtils.getCategoryDisplayName(category),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Divider(height: 24),

                  // Event details
                  _buildPreviewRow(
                    context,
                    Icons.calendar_today,
                    '${DateFormat('dd MMM yyyy').format(startDate)} • ${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
                  ),
                  const SizedBox(height: 8),
                  _buildPreviewRow(context, Icons.location_on, locationName),
                  const SizedBox(height: 8),
                  _buildPreviewRow(context, Icons.people, '$capacity orang'),
                  const SizedBox(height: 8),
                  _buildPreviewRow(
                    context,
                    isFree ? Icons.card_giftcard : Icons.attach_money,
                    isFree ? 'Gratis' : CurrencyFormatter.formatToRupiah(price),
                  ),
                  // V2: Private Events - TODO: Re-enable for V2
                  // const SizedBox(height: 8),
                  // _buildPreviewRow(
                  //   context,
                  //   privacy == EventPrivacy.public ? Icons.public : Icons.lock,
                  //   privacy == EventPrivacy.public ? 'Publik' : 'Private',
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Widget _buildPreviewRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textEmphasis,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
