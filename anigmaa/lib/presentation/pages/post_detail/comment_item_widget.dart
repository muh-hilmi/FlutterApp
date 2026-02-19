// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../domain/entities/comment.dart';
import '../profile/profile_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onLike;
  final bool isSending;

  const CommentItem({
    super.key,
    required this.comment,
    this.onLike,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorHeader(context),
          const SizedBox(height: 4),
          _buildCommentContent(),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(context),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.secondary,
            backgroundImage: _getAvatarImage(),
            child: _getAvatarPlaceholder(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.author.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• ${_formatTimestamp(comment.createdAt)}',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (isSending) ...[
                    const SizedBox(width: 4),
                    Text(
                      '• Mengirim...',
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildLikeButton(),
      ],
    );
  }

  ImageProvider? _getAvatarImage() {
    return comment.author.avatar != null && comment.author.avatar!.isNotEmpty
        ? CachedNetworkImageProvider(comment.author.avatar!)
        : null;
  }

  Widget? _getAvatarPlaceholder() {
    return comment.author.avatar == null || comment.author.avatar!.isEmpty
        ? Text(
            comment.author.name.isNotEmpty
                ? comment.author.name[0].toUpperCase()
                : '?',
            style: AppTextStyles.captionSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          )
        : null;
  }

  String _formatTimestamp(DateTime timestamp) {
    return timeago.format(timestamp, locale: 'en_short');
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: isSending ? null : onLike,
      child: Opacity(
        opacity: isSending ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: comment.isLikedByCurrentUser
                ? AppColors.error.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                comment.isLikedByCurrentUser
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 14,
                color: comment.isLikedByCurrentUser
                    ? AppColors.error
                    : AppColors.textTertiary,
              ),
              if (comment.likesCount > 0) ...[
                const SizedBox(width: 3),
                Text(
                  '${comment.likesCount}',
                  style: AppTextStyles.captionSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: comment.isLikedByCurrentUser
                        ? AppColors.error
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentContent() {
    return Text(
      comment.content,
      style: AppTextStyles.bodySmall.copyWith(
        fontSize: 13,
        color: isSending ? AppColors.textTertiary : AppColors.textPrimary,
        height: 1.4,
        letterSpacing: -0.1,
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: comment.author.id),
      ),
    );
  }
}
