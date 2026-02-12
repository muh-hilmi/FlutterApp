import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';

/// Implementation of PostRepository following Clean Architecture principles
/// Handles data operations for posts with proper error handling and logging
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final AppLogger _logger = AppLogger();

  PostRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> getPosts({int limit = 20, int offset = 0}) async {
    try {
      _logger.info('Fetching posts from remote (limit: $limit, offset: $offset)');

      // Fetch from remote only
      final posts = await remoteDataSource.getPosts(limit: limit, offset: offset);
      _logger.info('Successfully fetched ${posts.length} posts');

      // TODO: Parse meta field from API response when backend implements pagination
      // REDNOTE: Backend needs to implement pagination metadata for proper pagination support
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: posts, meta: meta));
    } on Failure catch (e) {
      _logger.error('Failure fetching posts: $e');
      return Left(e);
    } catch (e, stackTrace) {
      _logger.error('Exception fetching posts: $e', e, stackTrace);
      return Left(ServerFailure('Failed to get posts: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> getPostById(String postId) async {
    try {
      _logger.info('Fetching post by ID: $postId');
      final post = await remoteDataSource.getPostById(postId);
      return Right(post);
    } on Failure catch (e) {
      _logger.error('Failure fetching post by ID: $e');
      return Left(e);
    } catch (e, stackTrace) {
      _logger.error('Exception fetching post by ID: $e', e, stackTrace);
      return Left(ServerFailure('Failed to get post: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> createPost(Post post) async {
    try {
      _logger.info('Creating new post of type: ${post.type}');

      final postData = {
        'content': post.content,
        'type': post.type.toString().split('.').last,
        'visibility': post.visibility.toString().split('.').last,
        if (post.imageUrls.isNotEmpty) 'image_urls': post.imageUrls,
        if (post.originalPost != null) 'original_post_id': post.originalPost!.id,
        if (post.attachedEvent != null) 'attached_event_id': post.attachedEvent!.id,
        if (post.poll != null) 'poll': _serializePoll(post.poll!),
      };

      final newPost = await remoteDataSource.createPost(postData);
      _logger.info('Successfully created post with ID: ${newPost.id}');
      return Right(newPost);
    } catch (e, stackTrace) {
      _logger.error('Failed to create post: $e', e, stackTrace);
      return Left(ServerFailure('Failed to create post: $e'));
    }
  }

  /// Serialize poll data for API request
  Map<String, dynamic> _serializePoll(Poll poll) {
    return {
      'id': poll.id,
      'question': poll.question,
      'options': poll.options.map((option) => {
        'id': option.id,
        'text': option.text,
      }).toList(),
      'ends_at': poll.endsAt.toIso8601String(),
    };
  }

  @override
  Future<Either<Failure, Post>> updatePost(Post post) async {
    try {
      _logger.info('Updating post with ID: ${post.id}');

      final postData = {
        'content': post.content,
        'type': post.type.toString().split('.').last,
        if (post.imageUrls.isNotEmpty) 'image_urls': post.imageUrls,
      };

      final updatedPost = await remoteDataSource.updatePost(post.id, postData);
      _logger.info('Successfully updated post: ${post.id}');
      return Right(updatedPost);
    } catch (e, stackTrace) {
      _logger.error('Failed to update post: $e', e, stackTrace);
      return Left(ServerFailure('Failed to update post: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      _logger.info('Deleting post with ID: $postId');
      await remoteDataSource.deletePost(postId);
      _logger.info('Successfully deleted post: $postId');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete post: $e', e, stackTrace);
      return Left(ServerFailure('Failed to delete post: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> likePost(String postId) async {
    try {
      _logger.info('Liking post: $postId');
      await remoteDataSource.likePost(postId);
      _logger.info('Successfully liked post: $postId');

      // TODO: Backend should return updated post data instead of placeholder
      // REDNOTE: This creates inconsistent state, backend needs to return full post object
      return Right(_createPlaceholderPost(postId));
    } catch (e, stackTrace) {
      _logger.error('Error liking post: $e', e, stackTrace);
      return Left(ServerFailure('Failed to like post: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> unlikePost(String postId) async {
    try {
      _logger.info('Unliking post: $postId');
      await remoteDataSource.unlikePost(postId);
      _logger.info('Successfully unliked post: $postId');

      // TODO: Backend should return updated post data instead of placeholder
      // REDNOTE: This creates inconsistent state, backend needs to return full post object
      return Right(_createPlaceholderPost(postId));
    } catch (e, stackTrace) {
      _logger.error('Error unliking post: $e', e, stackTrace);
      return Left(ServerFailure('Failed to unlike post: $e'));
    }
  }

  /// Creates a placeholder post for API responses that don't return full post data
  Post _createPlaceholderPost(String postId) {
    return Post(
      id: postId,
      author: User(
        id: '',
        email: '',
        name: '',
        createdAt: DateTime.now(),
        settings: const UserSettings(),
        stats: const UserStats(),
        privacy: const UserPrivacy(),
      ),
      content: '',
      type: PostType.text,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Either<Failure, Post>> repostPost(String postId, {String? quoteContent}) async {
    try {
      _logger.info('Reposting post: $postId${quoteContent != null ? ' with quote' : ''}');
      final post = await remoteDataSource.repostPost(postId, comment: quoteContent);
      _logger.info('Successfully reposted: $postId');
      return Right(post);
    } catch (e, stackTrace) {
      _logger.error('Failed to repost: $e', e, stackTrace);
      return Left(ServerFailure('Failed to repost post: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> undoRepost(String postId) async {
    try {
      _logger.info('Undoing repost: $postId');
      await remoteDataSource.undoRepost(postId);
      _logger.info('Successfully undone repost: $postId');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to undo repost: $e', e, stackTrace);
      return Left(ServerFailure('Failed to undo repost: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> bookmarkPost(String postId) async {
    try {
      _logger.info('Bookmarking post: $postId');
      await remoteDataSource.bookmarkPost(postId);
      _logger.info('Successfully bookmarked: $postId');

      // OPTIMIZATION: Return a placeholder post instead of making another API call
      // The UI will handle optimistic updates
      // TODO: Backend should return updated post data in bookmark/unbookmark response
      return Right(_createBookmarkPlaceholderPost(postId));
    } catch (e, stackTrace) {
      _logger.error('Failed to bookmark post: $e', e, stackTrace);
      return Left(ServerFailure('Failed to bookmark post: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> unbookmarkPost(String postId) async {
    try {
      _logger.info('Unbookmarking post: $postId');
      await remoteDataSource.unbookmarkPost(postId);
      _logger.info('Successfully unbookmarked: $postId');

      // OPTIMIZATION: Return a placeholder post instead of making another API call
      // The UI will handle optimistic updates
      // TODO: Backend should return updated post data in bookmark/unbookmark response
      return Right(_createBookmarkPlaceholderPost(postId, isBookmarked: false));
    } catch (e, stackTrace) {
      _logger.error('Failed to unbookmark post: $e', e, stackTrace);
      return Left(ServerFailure('Failed to unbookmark post: $e'));
    }
  }

  /// Creates a placeholder post for bookmark/unbookmark operations
  /// This avoids making unnecessary API calls
  Post _createBookmarkPlaceholderPost(String postId, {bool isBookmarked = true}) {
    // Create a minimal post object for optimistic updates
    // The BLoC will handle proper state management
    return Post(
      id: postId,
      author: User(
        id: '',
        email: '',
        name: '',
        createdAt: DateTime.now(),
        settings: const UserSettings(),
        stats: const UserStats(),
        privacy: const UserPrivacy(),
      ),
      content: '',
      type: PostType.text,
      createdAt: DateTime.now(),
      isBookmarked: isBookmarked,
    );
  }

  @override
  Future<Either<Failure, List<Post>>> getBookmarkedPosts({int limit = 20, int offset = 0}) async {
    try {
      final posts = await remoteDataSource.getBookmarkedPosts(limit: limit, offset: offset);
      return Right(posts.cast<Post>());
    } catch (e) {
      return Left(ServerFailure('Failed to get bookmarked posts: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Comment>>> getComments(String postId, {int limit = 20, int offset = 0}) async {
    try {
      // Convert offset to page for now (until backend supports offset)
      final page = (offset ~/ limit) + 1;

      // Fetch from remote only - no fallback
      final comments = await remoteDataSource.getPostComments(postId, page: page, limit: limit);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: comments, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get comments: $e'));
    }
  }

  @override
  Future<Either<Failure, Comment>> createComment(Comment comment) async {
    try {
      final commentData = {
        'content': comment.content,
        'author_id': comment.author.id,
        if (comment.parentCommentId != null) 'parent_comment_id': comment.parentCommentId,
      };
      final newComment = await remoteDataSource.createComment(comment.postId, commentData);
      return Right(newComment);
    } catch (e) {
      _logger.error('Error creating comment: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Comment>> updateComment(Comment comment) async {
    try {
      final commentData = {
        'content': comment.content,
      };
      final updatedComment = await remoteDataSource.updateComment(comment.id, commentData);
      return Right(updatedComment);
    } catch (e) {
      return Left(ServerFailure('Failed to update comment: $e'));
    }
  }

  @override
  Future<Either<Failure, Comment>> likeComment(String postId, String commentId) async {
    try {
      _logger.info('Liking comment $commentId on post $postId...');
      await remoteDataSource.likeComment(postId, commentId);
      _logger.info('Like comment successful');

      // Create a placeholder comment - the bloc will handle optimistic update
      return Right(Comment(
        id: commentId,
        postId: postId,
        author: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        content: '',
        createdAt: DateTime.now(),
        isLikedByCurrentUser: true,
      ));
    } catch (e, stackTrace) {
      _logger.error('Error liking comment: $e', e, stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Comment>> unlikeComment(String postId, String commentId) async {
    try {
      _logger.info('Unliking comment $commentId on post $postId...');
      await remoteDataSource.unlikeComment(postId, commentId);
      _logger.info('Unlike comment successful');

      // Create a placeholder comment - the bloc will handle optimistic update
      return Right(Comment(
        id: commentId,
        postId: postId,
        author: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        content: '',
        createdAt: DateTime.now(),
        isLikedByCurrentUser: false,
      ));
    } catch (e, stackTrace) {
      _logger.error('Error unliking comment: $e', e, stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(String commentId) async {
    try {
      await remoteDataSource.deleteComment(commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete comment: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> getFeedPosts({int limit = 20, int offset = 0}) async {
    try {
      final posts = await remoteDataSource.getPosts(limit: limit, offset: offset);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: posts, meta: meta));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> getUserPosts(String userId, {int limit = 20, int offset = 0}) async {
    try {
      // TODO: Use proper backend endpoint GET /users/{id}/posts instead of filtering
      final posts = await remoteDataSource.getPostsByUser(userId, page: (offset ~/ limit) + 1, limit: limit);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: posts, meta: meta));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sharePost(String postId) async {
    // TODO: Implement share tracking
    return const Right(null);
  }
}
