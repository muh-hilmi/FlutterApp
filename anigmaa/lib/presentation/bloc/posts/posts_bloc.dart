import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_posts.dart';
import '../../../domain/usecases/create_post.dart';
import '../../../domain/usecases/like_post.dart';
import '../../../domain/usecases/unlike_post.dart';
import '../../../domain/usecases/repost_post.dart';
import '../../../domain/usecases/get_comments.dart';
import '../../../domain/usecases/create_comment.dart';
import '../../../domain/usecases/like_comment.dart';
import '../../../domain/usecases/unlike_comment.dart';
import '../../../domain/usecases/bookmark_post.dart';
import '../../../domain/usecases/unbookmark_post.dart';
import '../../../domain/usecases/get_bookmarked_posts.dart';
import 'posts_event.dart';
import 'posts_state.dart';
import '../../../domain/entities/comment.dart';

const int postsPerPage = 20;

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPosts getPosts;
  final CreatePost createPost;
  final LikePost likePost;
  final UnlikePost unlikePost;
  final RepostPost repostPost;
  final GetComments getComments;
  final CreateComment createComment;
  final LikeComment likeComment;
  final UnlikeComment unlikeComment;
  final BookmarkPost bookmarkPost;
  final UnbookmarkPost unbookmarkPost;
  final GetBookmarkedPosts getBookmarkedPosts;

  PostsBloc({
    required this.getPosts,
    required this.createPost,
    required this.likePost,
    required this.unlikePost,
    required this.repostPost,
    required this.getComments,
    required this.createComment,
    required this.likeComment,
    required this.unlikeComment,
    required this.bookmarkPost,
    required this.unbookmarkPost,
    required this.getBookmarkedPosts,
  }) : super(PostsInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<RefreshPosts>(_onRefreshPosts);
    on<LoadMorePosts>(_onLoadMorePosts);
    on<CreatePostRequested>(_onCreatePost);
    on<LikePostToggled>(_onLikePostToggled);
    on<RepostRequested>(_onRepostRequested);
    on<LoadComments>(_onLoadComments);
    on<CreateCommentRequested>(_onCreateComment);
    on<LikeCommentToggled>(_onLikeCommentToggled);
    on<DeleteCommentRequested>(_onDeleteComment);
    on<SavePostToggled>(_onSavePostToggled);
    on<LoadSavedPosts>(_onLoadSavedPosts);
  }

  // Helper method to get current PostsLoaded state safely
  PostsLoaded? _getCurrentState() {
    return state is PostsLoaded ? state as PostsLoaded : null;
  }

  // Helper method to handle failure cases with error messages
  void _handleFailure(
    Emitter<PostsState> emit,
    PostsLoaded currentState,
    String errorMessage, {
    bool isCreatingPost = false,
  }) {
    emit(
      currentState.copyWith(
        isCreatingPost: isCreatingPost,
        createErrorMessage: errorMessage,
      ),
    );
  }

  // Helper method to update comments in state
  Map<String, List<Comment>> _updateCommentsInState(
    PostsLoaded currentState,
    String postId,
    List<Comment> Function(List<Comment>?) updateFn,
  ) {
    final updatedComments = Map<String, List<Comment>>.from(
      currentState.commentsByPostId,
    );
    final existingComments = updatedComments[postId] ?? [];
    updatedComments[postId] = updateFn(existingComments);
    return updatedComments;
  }

  // Helper method to add comment optimistically
  void _addCommentOptimistically(
    Emitter<PostsState> emit,
    PostsLoaded currentState,
    Comment comment,
  ) {
    final updatedComments = _updateCommentsInState(
      currentState,
      comment.postId,
      (existing) => [comment, ...existing ?? []],
    );

    // Update comment count in posts
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == comment.postId) {
        return post.copyWith(commentsCount: post.commentsCount + 1);
      }
      return post;
    }).toList();

    // Mark comment as sending
    final sendingIds = Set<String>.from(currentState.sendingCommentIds);
    sendingIds.add(comment.id);

    emit(
      currentState.copyWith(
        posts: updatedPosts,
        commentsByPostId: updatedComments,
        sendingCommentIds: sendingIds,
      ),
    );
  }

  // Helper method to remove comment optimistically
  void _removeCommentOptimistically(
    Emitter<PostsState> emit,
    PostsLoaded currentState,
    Comment comment,
  ) {
    final updatedComments = _updateCommentsInState(
      currentState,
      comment.postId,
      (existing) => existing?.where((c) => c.id != comment.id).toList() ?? [],
    );

    // Update comment count in posts
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == comment.postId) {
        return post.copyWith(
          commentsCount: post.commentsCount > 0 ? post.commentsCount - 1 : 0,
        );
      }
      return post;
    }).toList();

    // Remove from sending state
    final sendingIds = Set<String>.from(currentState.sendingCommentIds);
    sendingIds.remove(comment.id);

    emit(
      currentState.copyWith(
        posts: updatedPosts,
        commentsByPostId: updatedComments,
        sendingCommentIds: sendingIds,
      ),
    );
  }

  // Helper method to update comment in place
  void _updateCommentInPlace(
    Emitter<PostsState> emit,
    PostsLoaded currentState,
    String postId,
    String commentId,
    Comment Function(Comment) updateFn,
  ) {
    final updatedComments = _updateCommentsInState(currentState, postId, (
      existing,
    ) {
      if (existing == null) return [];
      return existing.map((c) => c.id == commentId ? updateFn(c) : c).toList();
    });

    emit(currentState.copyWith(commentsByPostId: updatedComments));
  }

  // Helper method to replace comment in place
  void _replaceCommentInPlace(
    Emitter<PostsState> emit,
    PostsLoaded currentState,
    String postId,
    String tempCommentId,
    Comment newComment,
  ) {
    final updatedComments = _updateCommentsInState(currentState, postId, (
      existing,
    ) {
      if (existing == null) return [];
      return existing
          .map((c) => c.id == tempCommentId ? newComment : c)
          .toList();
    });

    // Remove from sending state
    final sendingIds = Set<String>.from(currentState.sendingCommentIds);
    sendingIds.remove(tempCommentId);

    emit(
      currentState.copyWith(
        commentsByPostId: updatedComments,
        sendingCommentIds: sendingIds,
      ),
    );
  }

  // Helper method for optimistic post updates
  Future<void> _performOptimisticPostUpdate(
    Emitter<PostsState> emit,
    String postId,
    bool newIsLikedState,
    Future<void> Function() apiCall, {
    bool? newBookmarkedState,
  }) async {
    final currentState = _getCurrentState();
    if (currentState == null) return;

    final originalPost = currentState.posts.firstWhere((p) => p.id == postId);

    // Create optimistic update
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isLikedByCurrentUser: newIsLikedState,
          likesCount: newIsLikedState
              ? post.likesCount + 1
              : (post.likesCount > 0 ? post.likesCount - 1 : 0),
          isBookmarked: newBookmarkedState ?? post.isBookmarked,
        );
      }
      return post;
    }).toList();

    emit(currentState.copyWith(posts: updatedPosts));

    // Execute API call
    try {
      await apiCall();
      // Success - optimistic update already applied
    } catch (e) {
      // Revert optimistic update on failure
      final revertedPosts = currentState.posts.map((post) {
        if (post.id == postId) {
          return originalPost;
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: revertedPosts));
    }
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostsState> emit) async {
    emit(PostsLoading());

    try {
      final result = await getPosts(
        const GetPostsParams(limit: postsPerPage, offset: 0),
      );

      result.fold(
        (failure) {
          emit(PostsError('Failed to load posts: ${failure.toString()}'));
        },
        (paginatedResponse) {
          emit(
            PostsLoaded(
              posts: paginatedResponse.data,
              paginationMeta: paginatedResponse.meta,
            ),
          );
        },
      );
    } catch (e) {
      emit(PostsError('Exception loading posts: $e'));
    }
  }

  Future<void> _onRefreshPosts(
    RefreshPosts event,
    Emitter<PostsState> emit,
  ) async {
    final result = await getPosts(
      const GetPostsParams(limit: postsPerPage, offset: 0),
    );

    result.fold(
      (failure) => emit(const PostsError('Failed to refresh posts')),
      (paginatedResponse) {
        final currentState = _getCurrentState();
        emit(
          PostsLoaded(
            posts: paginatedResponse.data,
            commentsByPostId: currentState?.commentsByPostId ?? const {},
            paginationMeta: paginatedResponse.meta,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMorePosts(
    LoadMorePosts event,
    Emitter<PostsState> emit,
  ) async {
    final currentState = _getCurrentState();
    if (currentState == null) return;

    if (currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await getPosts(
        GetPostsParams(limit: postsPerPage, offset: currentState.currentOffset),
      );

      result.fold(
        (failure) {
          emit(currentState.copyWith(isLoadingMore: false));
        },
        (paginatedResponse) {
          final updatedPosts = [
            ...currentState.posts,
            ...paginatedResponse.data,
          ];
          emit(
            currentState.copyWith(
              posts: updatedPosts,
              paginationMeta: paginatedResponse.meta,
              isLoadingMore: false,
            ),
          );
        },
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onCreatePost(
    CreatePostRequested event,
    Emitter<PostsState> emit,
  ) async {
    final currentState = _getCurrentState();
    if (currentState != null) {
      emit(currentState.copyWith(isCreatingPost: true));
    }

    final result = await createPost(CreatePostParams(post: event.post));

    result.fold(
      (failure) {
        final latestState = _getCurrentState();
        if (latestState != null) {
          _handleFailure(
            emit,
            latestState,
            'Gagal bikin postingan: ${failure.message}',
            isCreatingPost: false,
          );
        }
      },
      (newPost) {
        final latestState = _getCurrentState();
        if (latestState != null) {
          final updatedPosts = [newPost, ...latestState.posts];
          emit(
            latestState.copyWith(
              posts: updatedPosts,
              isCreatingPost: false,
              successMessage: 'Post berhasil dibuat! 🎉',
            ),
          );
        }
      },
    );
  }

  Future<void> _onLikePostToggled(
    LikePostToggled event,
    Emitter<PostsState> emit,
  ) async {
    await _performOptimisticPostUpdate(
      emit,
      event.postId,
      event.isCurrentlyLiked,
      () async {
        final result = event.isCurrentlyLiked
            ? await likePost(event.postId)
            : await unlikePost(event.postId);
        result.fold((failure) => throw Exception(failure.toString()), (_) {});
      },
    );
  }

  Future<void> _onRepostRequested(
    RepostRequested event,
    Emitter<PostsState> emit,
  ) async {
    final result = await repostPost(
      RepostPostParams(postId: event.postId, quoteContent: event.quoteContent),
    );

    result.fold(
      (failure) {
        // Don't emit error - just log it. Keep posts visible!
      },
      (repostedPost) {
        add(RefreshPosts());
      },
    );
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<PostsState> emit,
  ) async {
    final currentState = _getCurrentState();
    if (currentState == null) return;

    final result = await getComments(GetCommentsParams(postId: event.postId));

    result.fold(
      (failure) {
        final updatedComments = _updateCommentsInState(
          currentState,
          event.postId,
          (_) => [],
        );
        emit(currentState.copyWith(commentsByPostId: updatedComments));
      },
      (paginatedResponse) {
        final updatedComments = _updateCommentsInState(
          currentState,
          event.postId,
          (_) => paginatedResponse.data,
        );
        emit(currentState.copyWith(commentsByPostId: updatedComments));
      },
    );
  }

  Future<void> _onCreateComment(
    CreateCommentRequested event,
    Emitter<PostsState> emit,
  ) async {
    final currentState = _getCurrentState();
    if (currentState == null) return;

    _addCommentOptimistically(emit, currentState, event.comment);

    final result = await createComment(
      CreateCommentParams(comment: event.comment),
    );

    result.fold(
      (failure) {
        final latestState = _getCurrentState();
        if (latestState != null) {
          _removeCommentOptimistically(emit, latestState, event.comment);
        }
      },
      (newComment) {
        final latestState = _getCurrentState();
        if (latestState != null) {
          _replaceCommentInPlace(
            emit,
            latestState,
            event.comment.postId,
            event.comment.id,
            newComment,
          );
        }
      },
    );
  }

  Future<void> _onLikeCommentToggled(
    LikeCommentToggled event,
    Emitter<PostsState> emit,
  ) async {
    final currentState = _getCurrentState();
    if (currentState == null) return;

    // Optimistic update
    _updateCommentInPlace(emit, currentState, event.postId, event.commentId, (
      comment,
    ) {
      final newLikeCount = event.isCurrentlyLiked
          ? (comment.likesCount > 0 ? comment.likesCount - 1 : 0)
          : comment.likesCount + 1;
      return comment.copyWith(
        isLikedByCurrentUser: !event.isCurrentlyLiked,
        likesCount: newLikeCount,
      );
    });

    // Make API call
    final result = event.isCurrentlyLiked
        ? await unlikeComment(
            UnlikeCommentParams(
              postId: event.postId,
              commentId: event.commentId,
            ),
          )
        : await likeComment(
            LikeCommentParams(postId: event.postId, commentId: event.commentId),
          );

    result.fold(
      (failure) {
        final latestState = _getCurrentState();
        if (latestState != null) {
          // Revert optimistic update
          _updateCommentInPlace(
            emit,
            latestState,
            event.postId,
            event.commentId,
            (comment) {
              final revertedLikeCount = event.isCurrentlyLiked
                  ? comment.likesCount + 1
                  : (comment.likesCount > 0 ? comment.likesCount - 1 : 0);
              return comment.copyWith(
                isLikedByCurrentUser: event.isCurrentlyLiked,
                likesCount: revertedLikeCount,
              );
            },
          );
        }
      },
      (_) {
        // Success - optimistic update already applied
      },
    );
  }

  Future<void> _onDeleteComment(
    DeleteCommentRequested event,
    Emitter<PostsState> emit,
  ) async {
    final currentState = _getCurrentState();
    if (currentState == null) return;

    // Optimistically remove comment from state
    final updatedComments = _updateCommentsInState(
      currentState,
      event.postId,
      (existing) =>
          existing?.where((c) => c.id != event.commentId).toList() ?? [],
    );

    // Update comment count in posts
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(
          commentsCount: post.commentsCount > 0 ? post.commentsCount - 1 : 0,
        );
      }
      return post;
    }).toList();

    emit(
      currentState.copyWith(
        posts: updatedPosts,
        commentsByPostId: updatedComments,
      ),
    );

    // TODO: Call actual delete API here
    // For now, the optimistic update is enough for UI demo
  }

  Future<void> _onSavePostToggled(
    SavePostToggled event,
    Emitter<PostsState> emit,
  ) async {
    await _performOptimisticPostUpdate(
      emit,
      event.postId,
      _getCurrentState()?.posts
              .firstWhere((p) => p.id == event.postId)
              .isLikedByCurrentUser ??
          false,
      () async {
        final result = event.isCurrentlySaved
            ? await unbookmarkPost(event.postId)
            : await bookmarkPost(event.postId);
        result.fold((failure) => throw Exception(failure.toString()), (
          updatedPost,
        ) {
          final latestState = _getCurrentState();
          if (latestState != null) {
            final serverUpdatedPosts = latestState.posts.map((post) {
              if (post.id == event.postId) {
                return updatedPost;
              }
              return post;
            }).toList();
            emit(latestState.copyWith(posts: serverUpdatedPosts));
          }
        });
      },
      newBookmarkedState: !event.isCurrentlySaved,
    );
  }

  Future<void> _onLoadSavedPosts(
    LoadSavedPosts event,
    Emitter<PostsState> emit,
  ) async {
    emit(PostsLoading());

    try {
      final result = await getBookmarkedPosts(
        const GetBookmarkedPostsParams(limit: postsPerPage, offset: 0),
      );

      result.fold(
        (failure) {
          emit(PostsError('Failed to load saved posts: ${failure.toString()}'));
        },
        (posts) {
          emit(PostsLoaded(posts: posts, paginationMeta: null));
        },
      );
    } catch (e) {
      emit(PostsError('Exception loading saved posts: $e'));
    }
  }
}
