import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../pages/post_detail/post_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommentPreview extends StatefulWidget {
  final Post post;
  final bool showCommentPreview;
  final bool showActionBar;

  const CommentPreview({
    super.key,
    required this.post,
    this.showCommentPreview = true,
    this.showActionBar = true,
  });

  @override
  State<CommentPreview> createState() => _CommentPreviewState();
}

class _CommentPreviewState extends State<CommentPreview> {
  List<Map<String, String>> _previewComments = [];
  bool _hasLoaded = false;
  int? _loadedCommentCount; // cached once loaded — prevents reverting to stale backend count

  @override
  void initState() {
    super.initState();
    _loadCommentPreview();
  }

  void _loadCommentPreview() {
    if (widget.showCommentPreview && !_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PostsBloc>().add(LoadComments(widget.post.id));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showCommentPreview) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        if (state is PostsLoaded &&
            state.commentsByPostId.containsKey(widget.post.id)) {
          final comments = state.commentsByPostId[widget.post.id]!;
          _loadedCommentCount = comments.length; // cache — survives PostsLoading rebuilds
          if (comments.isNotEmpty) {
            _previewComments = comments.take(3).map((comment) {
              return {
                'author': comment.author.name,
                'content': comment.content,
              };
            }).toList();
          }
        }

        // Show loading skeleton if comments should exist but haven't loaded yet
        if (_previewComments.isEmpty && !_hasLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (_previewComments.isEmpty) {
          return const SizedBox.shrink();
        }

        // Use cached loaded count — never revert to stale backend commentsCount
        final actualCommentCount =
            _loadedCommentCount ?? widget.post.commentsCount;

        final commentContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._previewComments.map((comment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                      letterSpacing: -0.1,
                    ),
                    children: [
                      TextSpan(
                        text: '${comment['author']} ',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: comment['content'],
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Show "view all comments" at the bottom
            if (actualCommentCount > _previewComments.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Liat semua $actualCommentCount komentar',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );

        // Only wrap with GestureDetector if showActionBar is true (not in detail view)
        if (widget.showActionBar) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: widget.post),
                ),
              );
            },
            child: commentContent,
          );
        }

        return commentContent;
      },
    );
  }
}
