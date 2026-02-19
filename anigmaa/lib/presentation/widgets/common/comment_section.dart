import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import 'comment_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommentSection extends StatefulWidget {
  final Post post;
  final Function(Comment)? onReply;

  const CommentSection({
    super.key,
    required this.post,
    this.onReply,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  @override
  void initState() {
    super.initState();
    context.read<PostsBloc>().add(LoadComments(widget.post.id));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return _buildLoadingState();
          }

          if (state is! PostsLoaded) {
            return const SizedBox.shrink();
          }

          final comments = state.commentsByPostId[widget.post.id] ?? [];

          if (comments.isEmpty) {
            return _buildEmptyState();
          }

          // Separate top-level comments and replies
          final topLevelComments = comments.where((c) => !c.isReply).toList();

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: topLevelComments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final comment = topLevelComments[index];
              final replies = comments
                  .where((c) => c.parentCommentId == comment.id)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommentItem(
                    post: widget.post,
                    comment: comment,
                    onLike: () {
                      context.read<PostsBloc>().add(
                            LikeCommentToggled(
                              widget.post.id,
                              comment.id,
                              comment.isLikedByCurrentUser,
                            ),
                          );
                    },
                    onDelete: () {
                      context.read<PostsBloc>().add(
                            DeleteCommentRequested(widget.post.id, comment.id),
                          );
                    },
                    onReply: widget.onReply,
                  ),
                  // Show replies
                  if (replies.isNotEmpty)
                    ...replies.map(
                      (reply) => CommentItem(
                        post: widget.post,
                        comment: reply,
                        isReply: true,
                        onLike: () {
                          context.read<PostsBloc>().add(
                                LikeCommentToggled(
                                  widget.post.id,
                                  reply.id,
                                  reply.isLikedByCurrentUser,
                                ),
                              );
                        },
                        onDelete: () {
                          context.read<PostsBloc>().add(
                                DeleteCommentRequested(widget.post.id, reply.id),
                              );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 32,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada komentar',
            style: AppTextStyles.bodyLargeBold.copyWith(
              color: AppColors.textEmphasis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jadilah yang pertama memberikan komentar!',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
