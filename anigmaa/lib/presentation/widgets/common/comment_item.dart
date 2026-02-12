import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';

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
      backgroundColor: const Color(0xFFF3F4F6),
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? CachedNetworkImageProvider(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isReply ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timeago.format(comment.createdAt, locale: 'id'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),

        // Comment content
        Text(
          comment.content,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF374151),
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
                      ? const Color(0xFFED4956)
                      : const Color(0xFF9CA3AF),
                ),
                if (comment.likesCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${comment.likesCount}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
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
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  if (comment.repliesCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${comment.repliesCount}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
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
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.more_horiz,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFED4956)),
                title: Text(
                  'Hapus Komentar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
