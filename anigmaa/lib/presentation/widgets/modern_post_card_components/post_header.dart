import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../domain/entities/post.dart';
import '../../pages/profile/profile_screen.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback? onMenuTap;

  const PostHeader({super.key, required this.post, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: post.author.id),
              ),
            );
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondary,
            backgroundImage:
                post.author.avatar != null && post.author.avatar!.isNotEmpty
                ? CachedNetworkImageProvider(post.author.avatar!)
                : null,
            child: post.author.avatar == null || post.author.avatar!.isEmpty
                ? Text(
                    post.author.name[0].toUpperCase(),
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.name,
                style: AppTextStyles.bodyLargeBold.copyWith(
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),

              // Interests tags
              if (post.author.interests.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: post.author.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        interest,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Time
              Text(
                timeago.format(post.createdAt, locale: 'en_short'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),

        // More Menu - rounded button
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: AppColors.textEmphasis,
            ),
            onPressed: onMenuTap ?? () => _showPostMenu(context),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                context,
                icon: post.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                iconColor: AppColors.secondary,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                title: post.isBookmarked
                    ? 'Hapus dari Simpanan'
                    : 'Simpan Post',
                onTap: () {
                  Navigator.pop(context);
                  context.read<PostsBloc>().add(
                    SavePostToggled(post.id, post.isBookmarked),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.link_rounded,
                iconColor: AppColors.textSecondary,
                backgroundColor: AppColors.surface,
                title: 'Salin Link',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.flag_outlined,
                iconColor: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                title: 'Laporin',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
