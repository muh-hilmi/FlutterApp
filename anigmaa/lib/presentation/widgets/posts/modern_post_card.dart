import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_state.dart';
import '../../pages/post_detail/post_detail_screen.dart';
import '../modern_post_card_components/post_header.dart';
import '../modern_post_card_components/post_content.dart';
import '../modern_post_card_components/post_images.dart';
import '../modern_post_card_components/event_attachment.dart';
import '../modern_post_card_components/post_poll.dart';
import '../modern_post_card_components/post_action_bar.dart';
import '../modern_post_card_components/comment_preview.dart';
import '../../../core/theme/app_colors.dart';

class ModernPostCard extends StatelessWidget {
  final Post post;
  final bool showCommentPreview;
  final bool showActionBar;

  const ModernPostCard({
    super.key,
    required this.post,
    this.showCommentPreview = true,
    this.showActionBar = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when this specific post changes
    return BlocSelector<PostsBloc, PostsState, Post?>(
      selector: (state) {
        if (state is PostsLoaded) {
          try {
            return state.posts.firstWhere((p) => p.id == post.id);
          } catch (e) {
            // Post not found in state
            return null;
          }
        }
        return null;
      },
      builder: (context, updatedPost) {
        final currentPost = updatedPost ?? post;

        final cardContent = Container(
          color: AppColors.white,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: PostHeader(post: currentPost),
              ),

              // Post Text Content
              if (currentPost.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: PostContent(content: currentPost.content),
                ),

              // Post Images
              if (currentPost.imageUrls.isNotEmpty)
                PostImages(imageUrls: currentPost.imageUrls),

              // Event Mini Card (if has event)
              if (currentPost.attachedEvent != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EventAttachment(post: currentPost),
                ),

              // Poll (if has poll)
              if (currentPost.poll != null) const PostPoll(),

              // Action Bar
              if (showActionBar)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: BlocBuilder<PostsBloc, PostsState>(
                    buildWhen: (previous, current) {
                      // Only rebuild when comments for THIS post change
                      if (previous is PostsLoaded && current is PostsLoaded) {
                        final previousCount = previous.commentsByPostId[currentPost.id]?.length;
                        final currentCount = current.commentsByPostId[currentPost.id]?.length;
                        return previousCount != currentCount;
                      }
                      return previous.runtimeType != current.runtimeType;
                    },
                    builder: (context, state) {
                      final actualCommentCount =
                          state is PostsLoaded &&
                              state.commentsByPostId.containsKey(currentPost.id)
                          ? state.commentsByPostId[currentPost.id]!.length
                          : null;

                      return PostActionBar(
                        post: currentPost,
                        actualCommentCount: actualCommentCount,
                      );
                    },
                  ),
                ),

              // Comment Preview - always show if enabled, widget handles loading
              if (showCommentPreview)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: CommentPreview(
                    post: currentPost,
                    showCommentPreview: showCommentPreview,
                    showActionBar: showActionBar,
                  ),
                ),
            ],
          ),
        );

        // Only wrap with GestureDetector if showActionBar is true (not in detail view)
        if (showActionBar) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: currentPost),
                ),
              );
            },
            child: cardContent,
          );
        }

        return cardContent;
      },
    );
  }
}
