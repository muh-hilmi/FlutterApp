import 'package:equatable/equatable.dart';
import '../../../core/models/pagination.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/comment.dart';

abstract class PostsState extends Equatable {
  const PostsState();

  @override
  List<Object?> get props => [];
}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<Post> posts;
  final Map<String, List<Comment>> commentsByPostId;
  final PaginationMeta? paginationMeta;
  final bool isLoadingMore;
  final bool isCreatingPost;
  final String? createErrorMessage;
  final String? successMessage;
  final Set<String> sendingCommentIds; // Track comments being sent

  const PostsLoaded({
    required this.posts,
    this.commentsByPostId = const {},
    this.paginationMeta,
    this.isLoadingMore = false,
    this.isCreatingPost = false,
    this.createErrorMessage,
    this.successMessage,
    this.sendingCommentIds = const {},
  });

  // Computed properties for backward compatibility
  bool get hasMore => paginationMeta?.hasNext ?? false;
  int get currentOffset => paginationMeta?.nextOffset ?? posts.length;

  PostsLoaded copyWith({
    List<Post>? posts,
    Map<String, List<Comment>>? commentsByPostId,
    PaginationMeta? paginationMeta,
    bool? isLoadingMore,
    bool? isCreatingPost,
    String? createErrorMessage,
    String? successMessage,
    Set<String>? sendingCommentIds,
  }) {
    return PostsLoaded(
      posts: posts ?? this.posts,
      commentsByPostId: commentsByPostId ?? this.commentsByPostId,
      paginationMeta: paginationMeta ?? this.paginationMeta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreatingPost: isCreatingPost ?? this.isCreatingPost,
      createErrorMessage: createErrorMessage,
      successMessage: successMessage,
      sendingCommentIds: sendingCommentIds ?? this.sendingCommentIds,
    );
  }

  PostsLoaded clearMessages() {
    return PostsLoaded(
      posts: posts,
      commentsByPostId: commentsByPostId,
      paginationMeta: paginationMeta,
      isLoadingMore: isLoadingMore,
      isCreatingPost: isCreatingPost,
      createErrorMessage: null,
      successMessage: null,
      sendingCommentIds: sendingCommentIds,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        commentsByPostId,
        paginationMeta,
        isLoadingMore,
        isCreatingPost,
        createErrorMessage,
        successMessage,
        sendingCommentIds,
      ];
}

class PostsError extends PostsState {
  final String message;

  const PostsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Offline state - shows cached data when network is unavailable
class PostsOffline extends PostsState {
  final List<Post> cachedPosts;
  final Map<String, List<Comment>> commentsByPostId;
  final PaginationMeta? paginationMeta;
  final String? message;

  const PostsOffline({
    required this.cachedPosts,
    this.commentsByPostId = const {},
    this.paginationMeta,
    this.message = 'Offline — menampilkan data terakhir',
  });

  @override
  List<Object?> get props => [cachedPosts, commentsByPostId, paginationMeta, message];
}

class CommentsLoading extends PostsState {
  final List<Post> posts;

  const CommentsLoading(this.posts);

  @override
  List<Object?> get props => [posts];
}

class CommentCreated extends PostsState {
  final Comment comment;

  const CommentCreated(this.comment);

  @override
  List<Object?> get props => [comment];
}
