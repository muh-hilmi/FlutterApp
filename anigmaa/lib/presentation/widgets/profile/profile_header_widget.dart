import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/user.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final User user;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isProcessing;
  final bool unfollowConfirmation;
  final VoidCallback? onFollowTap;
  final VoidCallback? onEditProfileTap;

  const ProfileHeaderWidget({
    super.key,
    required this.user,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isProcessing,
    required this.unfollowConfirmation,
    this.onFollowTap,
    this.onEditProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 0); // Header is now in ProfileInfoWidget
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildDefaultAvatar(),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textTertiary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ProfileInfoWidget extends StatelessWidget {
  final User user;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isProcessing;
  final bool unfollowConfirmation;
  final VoidCallback? onFollowTap;
  final VoidCallback? onEditProfileTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onPostsTap;
  final VoidCallback? onEventsTap;
  final VoidCallback? onManageEventsTap;
  final int postsCount;
  final int eventsHosted;
  final int activeEventsCount;

  const ProfileInfoWidget({
    super.key,
    required this.user,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isProcessing,
    required this.unfollowConfirmation,
    this.onFollowTap,
    this.onEditProfileTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onPostsTap,
    this.onEventsTap,
    this.onManageEventsTap,
    required this.postsCount,
    required this.eventsHosted,
    this.activeEventsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Avatar (Left), Name + Interests + Location (Right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(
                  avatarUrl: user.avatar,
                  name: user.name,
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        key: const Key('profile_name'),
                        user.name,
                        style: AppTextStyles.h2.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Interests (emoji only) + Location (side by side)
                      Row(
                        children: [
                          // Interests emojis
                          if (user.interests.isNotEmpty) ...[
                            _buildInterestsEmojiRow(),
                            const SizedBox(width: 8),
                          ],
                          // Location
                          if (user.location != null &&
                              user.location!.isNotEmpty) ...[
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                _formatLocation(user.location!),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Bio (Centered & Max 2 lines)
            SizedBox(
              width: double.infinity,
              child: Text(
                user.bio != null && user.bio!.isNotEmpty
                    ? user.bio!
                    : 'Belum ada bio.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: user.bio != null && user.bio!.isNotEmpty
                      ? AppColors.textEmphasis
                      : AppColors.textTertiary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 48),

            // Stats (Centered)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat(
                  '${_formatNumber(_getTotalEventCount(user))} Event',
                  null,
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  '${_formatNumber(user.stats.followersCount)} Pengikut',
                  onFollowersTap,
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  '${_formatNumber(user.stats.followingCount)} Mengikuti',
                  onFollowingTap,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            _buildActionButton(),

            // Events Hosted Section (Own profile only, only if has active events)
            if (isOwnProfile && activeEventsCount > 0) ...[
              const SizedBox(height: 16),
              _buildEventsHostedSection(),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsEmojiRow() {
    return Row(
      children: user.interests.take(5).map((interest) {
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            _getInterestEmoji(interest),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
    );
  }

  String _formatLocation(String location) {
    // Handle both old format (comma-separated) and new format (subAdministrativeArea only)
    final parts = location.split(',').map((e) => e.trim()).toList();

    // New format: directly "Kabupaten Boyolali" or "Kota Jakarta"
    if (parts.length == 1) {
      return location;
    }

    // Old format: "Kecamatan Ngemplak, Jawa Tengah"
    // Try to find Kabupaten/Kota in the parts
    for (final part in parts) {
      final lowerPart = part.toLowerCase();
      if (lowerPart.contains('kabupaten') || lowerPart.contains('kota')) {
        return part;
      }
    }

    // If no Kabupaten/Kota found, return the first part (skip "Kecamatan" prefix if exists)
    String firstPart = parts.first;
    if (firstPart.toLowerCase().startsWith('kecamatan')) {
      // Remove "Kecamatan" prefix
      return firstPart.substring(9).trim();
    }

    return parts.first;
  }

  String _getInterestEmoji(String interest) {
    switch (interest.toLowerCase()) {
      case 'meetup':
        return '👥';
      case 'sports':
        return '⚽';
      case 'workshop':
        return '🛠️';
      case 'networking':
        return '🤝';
      case 'food':
        return '🍕';
      case 'creative':
        return '🎨';
      case 'outdoor':
        return '🌳';
      case 'fitness':
        return '💪';
      case 'learning':
        return '📚';
      case 'social':
        return '🎉';
      default:
        return '✨';
    }
  }

  Widget _buildEventsHostedSection() {
    return Container(
      key: const Key('profile_events_hosted_section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBorder, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event kamu saat ini',
                      style: AppTextStyles.bodyMediumBold.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeEventsCount event',
                      key: const Key('profile_events_count'),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                key: const Key('profile_manage_events_button'),
                onPressed: onManageEventsTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Kelola',
                  style: AppTextStyles.button.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return ProfileActionButton(
      isOwnProfile: isOwnProfile,
      isFollowing: isFollowing,
      isProcessing: isProcessing,
      unfollowConfirmation: unfollowConfirmation,
      onFollowTap: onFollowTap,
      onEditProfileTap: onEditProfileTap,
    );
  }

  Widget _buildMiniStat(String label, VoidCallback? onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: AppTextStyles.bodyMediumBold.copyWith(
              fontSize: 13,
              color: AppColors.textEmphasis,
            ),
          ),
        ),
      ),
    );
  }

  int _getTotalEventCount(User user) {
    // Fallback: if totalUniqueEvents is 0, calculate from created + attended
    // Backend will provide accurate unique count later
    if (user.stats.totalUniqueEvents > 0) {
      return user.stats.totalUniqueEvents;
    }
    // Debug log
    AppLogger().info('[Profile] Events: created=${user.stats.eventsCreated}, attended=${user.stats.eventsAttended}, total=${user.stats.eventsCreated + user.stats.eventsAttended}');
    return user.stats.eventsCreated + user.stats.eventsAttended;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll('.0', '')}jt';
    } else if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}rb';
    }
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  // Legacy component kept for safety — not used in active screens
  const ProfileStatsRow({
    super.key,
    required this.postsCount,
    required this.eventsCount,
    required this.followersCount,
    required this.followingCount,
    this.onPostsTap,
    this.onEventsTap,
    this.onFollowersTap,
    this.onFollowingTap,
  });
  final int postsCount;
  final int eventsCount;
  final int followersCount;
  final int followingCount;
  final VoidCallback? onPostsTap;
  final VoidCallback? onEventsTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class ProfileStatItem extends StatelessWidget {
  const ProfileStatItem({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });
  final String value;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class ProfileActionButton extends StatelessWidget {
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isProcessing;
  final bool unfollowConfirmation;
  final VoidCallback? onFollowTap;
  final VoidCallback? onEditProfileTap;

  const ProfileActionButton({
    super.key,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isProcessing,
    required this.unfollowConfirmation,
    this.onFollowTap,
    this.onEditProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return _buildButton(
        label: 'Edit Profil',
        onTap: onEditProfileTap,
        isOutline: true,
        isPrimary: false,
      );
    } else {
      if (unfollowConfirmation) {
        return _buildButton(
          label: 'Batal Mengikuti?',
          onTap: isProcessing ? null : onFollowTap,
          isOutline: true,
          colorOverride: AppColors.error,
          isPrimary: false,
        );
      }
      return _buildButton(
        label: isFollowing ? 'Mengikuti' : 'Ikuti',
        onTap: isProcessing ? null : onFollowTap,
        isOutline: isFollowing,
        isPrimary: !isFollowing,
      );
    }
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onTap,
    required bool isOutline,
    required bool isPrimary,
    Color? colorOverride,
  }) {
    final accentColor = colorOverride ?? AppColors.secondary;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: isOutline ? Colors.transparent : accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutline
                ? BorderSide(color: AppColors.border, width: 1)
                : BorderSide.none,
          ),
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? accentColor.withValues(alpha: 0.3) : null,
          overlayColor: isOutline
              ? AppColors.surfaceAlt
              : AppColors.white.withValues(alpha: 0.2),
        ),
        child: isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutline ? AppColors.textPrimary : AppColors.white,
                  ),
                ),
              )
            : Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: isOutline
                      ? (colorOverride ?? AppColors.textPrimary)
                      : AppColors.white,
                ),
              ),
      ),
    );
  }
}
