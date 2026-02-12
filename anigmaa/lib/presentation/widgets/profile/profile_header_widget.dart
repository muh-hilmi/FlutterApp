import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.grey[400],
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
            // Top Section: Avatar (Left), Name + Location (Right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (user.location != null &&
                          user.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 13,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.location!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: user.bio != null && user.bio!.isNotEmpty
                      ? Colors.black87
                      : Colors.grey[500],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 48),

            // Simple Stats (Centered to match Bio)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat(
                  '${_formatNumber(user.stats.eventsAttended)} Ikut Event',
                  onEventsTap,
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

            // Events Hosted Section (Only for own profile)
            if (isOwnProfile) ...[
              const SizedBox(height: 16),
              _buildEventsHostedSection(),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsHostedSection() {
    return Container(
      key: const Key('profile_events_hosted_section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBBC863).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFFBBC863),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeEventsCount event',
                      key: const Key('profile_events_count'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                key: const Key('profile_manage_events_button'),
                onPressed: onManageEventsTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBC863),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Kelola'),
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll('.0', '')}jt';
    } else if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}rb';
    }

    // Indonesian format: 1.234 instead of 1,234 or 1.2rb
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  // Legacy component kept for safety if referenced elsewhere, but unused in this file
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
          colorOverride: Colors.red,
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
    final primaryColor = colorOverride ?? const Color(0xFFBBC863);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: isOutline ? Colors.transparent : primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutline
                ? BorderSide(color: Colors.grey[300]!, width: 1)
                : BorderSide.none,
          ),
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? primaryColor.withValues(alpha: 0.3) : null,
          overlayColor: isOutline
              ? Colors.grey[100]
              : Colors.white.withValues(alpha: 0.2),
        ),
        child: isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutline ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isOutline
                      ? (colorOverride ?? Colors.black)
                      : Colors.white,
                ),
              ),
      ),
    );
  }
}
