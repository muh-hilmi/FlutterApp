import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommentItem extends StatelessWidget {
  final Post post;
  final Comment comment;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final Function(Comment)? onReply;
  final bool isReply;

  const CommentItem({
    super.key,
    required this.post,
    required this.comment,
    this.onLike,
    this.onDelete,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if current user is the comment author
    final userBloc = context.read<UserBloc?>();
    final isOwner = userBloc != null &&
        userBloc.state is UserLoaded &&
        (userBloc.state as UserLoaded).user.id == comment.author.id;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isReply ? 12 : 16,
        vertical: 8,
      ),
      margin: EdgeInsets.only(
        left: isReply ? 48 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _buildAvatar(),

          const SizedBox(width: 10),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and content
                _buildCommentContent(),

                // Actions row
                _buildActions(isOwner),
              ],
            ),
          ),

          // More/delete button for owner
          if (isOwner) _buildMoreButton(context),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = comment.author.avatar;
    final initials = comment.author.name.isNotEmpty
        ? comment.author.name[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: isReply ? 14 : 16,
      backgroundColor: AppColors.surfaceAlt,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? CachedNetworkImageProvider(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              initials,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isReply ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            )
          : null,
    );
  }

  Widget _buildCommentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author name and time
        Row(
          children: [
            Text(
              comment.author.name,
              style: AppTextStyles.bodyMediumBold.copyWith(
                color: AppColors.textEmphasis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timeago.format(comment.createdAt, locale: 'id'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),

        // Comment content
        Text(
          comment.content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textEmphasis,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isOwner) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: onLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comment.isLikedByCurrentUser
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 14,
                  color: comment.isLikedByCurrentUser
                      ? AppColors.error
                      : AppColors.textTertiary,
                ),
                if (comment.likesCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${comment.likesCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reply button (only for top-level comments)
          if (!isReply) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => onReply?.call(comment),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  if (comment.repliesCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${comment.repliesCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeleteDialog(context),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.more_horiz,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  'Hapus Komentar',
                  style: AppTextStyles.bodyLargeBold,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
