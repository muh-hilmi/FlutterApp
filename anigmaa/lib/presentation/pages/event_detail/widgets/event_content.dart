import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/entities/event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../components/event_terms_section.dart';
import '../components/event_similar_list.dart';
import '../components/event_requirements_card.dart';
import '../components/event_qna_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../profile/profile_screen.dart';

class EventContent extends StatelessWidget {
  final Event event;

  const EventContent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Headliner (Brand & Context)
          _buildHeadlinerSection(context),
          const SizedBox(height: 24),

          // 2. The Core Specs (Logistics)
          _buildSpecsSection(context),
          const SizedBox(height: 24),

          // 3. Social & Story
          _buildSocialSection(context),
          const SizedBox(height: 16),

          // 4. Description
          Text(
            event.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textEmphasis,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // 5. Warning / Safe Guide
          _buildSafeGuideSection(),
          const SizedBox(height: 24),

          // 6. Requirements
          if (event.requirements != null && event.requirements!.isNotEmpty) ...[
            EventRequirementsCard(event: event),
            const SizedBox(height: 24),
          ],

          // 7. Map
          _buildLocationMap(),
          const SizedBox(height: 24),

          // 8. Terms, QnA & Similar
          EventTermsSection(),
          EventQnACard(event: event),
          const SizedBox(height: 24),
          EventSimilarList(currentEvent: event),
        ],
      ),
    );
  }

  Widget _buildHeadlinerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          event.title,
          style: AppTextStyles.h1.copyWith(
            fontSize: 28,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),

        // Organizer Row (Trust Signal)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: event.host.id),
              ),
            );
          },
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: event.host.avatar.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: event.host.avatar,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            event.host.name,
                            style: AppTextStyles.bodyLargeBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.host.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Penyelenggara',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // View Profile Button (Mini)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lihat',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Text(
          event.host.name.isNotEmpty ? event.host.name[0].toUpperCase() : '?',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Date Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatFullDate(event.startTime),
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatEventTime(event.startTime)} • ${_getRelativeTime(event.startTime)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // Location Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.location.name,
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ketuk peta untuk detail',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    // If 0 attendees, show a "Be the first" or simple "0 joining" message
    if (event.currentAttendees == 0) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Belum ada yang join. Jadilah yang pertama!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Face Pile using simple Container circles (simulated)
        // Only show pile if we have attendees
        SizedBox(
          width: 80, // Approximate width for 3 overlapping avatars
          height: 32,
          child: Stack(
            children: [
              // In a real app, logic would map user avatars.
              // For now, we use placeholders to simulate the "Vibe".
              // Right-most (bottom-most in stack)
              Positioned(
                left: 40,
                child: _buildMiniAvatarPlaceholder(AppColors.info.withValues(alpha: 0.2)),
              ),
              Positioned(
                left: 20,
                child: _buildMiniAvatarPlaceholder(AppColors.secondary.withValues(alpha: 0.2)),
              ),
              Positioned(
                left: 0,
                child: _buildMiniAvatarPlaceholder(AppColors.warning.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: '${event.currentAttendees} orang',
                style: AppTextStyles.bodyMediumBold,
              ),
              const TextSpan(text: ' akan hadir'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAvatarPlaceholder(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: const Icon(Icons.person, size: 16, color: AppColors.textTertiary),
    );
  }

  Widget _buildSafeGuideSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFE58F).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFFAAD14),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Datang 15 menit lebih awal. Hati-hati penipuan.',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF8c6b1d),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = localDate.difference(now);
    final days = difference.inDays;

    if (days == 0) return '(Hari ini)';
    if (days == 1) return '(Besok)';
    if (days < 0) return '(Selesai)';
    return '($days hari lagi)';
  }

  Widget _buildLocationMap() {
    final eventLoc = LatLng(event.location.latitude, event.location.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peta Lokasi',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _openMap(
            event.location.name,
            event.location.latitude,
            event.location.longitude,
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Real Map Preview - Wrapped in IgnorePointer to allow InkWell to catch taps
                  IgnorePointer(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: eventLoc,
                        zoom: 15.0,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(event.id),
                          position: eventLoc,
                        ),
                      },
                      zoomGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                    ),
                  ),

                  // Gradient Overlay for readability
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Location Label Overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: IgnorePointer(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event.location.name,
                              style: AppTextStyles.bodyMediumBold.copyWith(
                                color: AppColors.white,
                                shadows: [
                                  Shadow(
                                    color: AppColors.primary.withValues(alpha: 0.45),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(String location, double lat, double lng) async {
    final query = Uri.encodeComponent(location);

    // Google Maps: Use name for UX, or loc:lat,lng for exact spot with label
    // The 'query' parameter in Google Maps Search API works best with the name for UX
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    // Apple Maps: q=name and ll=coords works best to show name at exact spot
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?q=$query&ll=$lat,$lng',
    );

    // Android/Generic Geo: lat,lng?q=lat,lng(label) shows name at coords
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($query)');

    try {
      // 1. Try Google Maps URL (Name search provides best UX)
      if (await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication))
        return;

      // 2. Try Apple Maps (Supports name + specific coordinates)
      if (await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication))
        return;

      // 3. Try generic geo scheme (Supports coordinates with parenthetical label)
      if (await launchUrl(geoUrl)) return;

      throw 'Could not launch maps';
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  String _formatFullDate(DateTime date) {
    final localDate = date.toLocal();
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return '${days[localDate.weekday - 1]}, ${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
  }

  String _formatEventTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }
}
