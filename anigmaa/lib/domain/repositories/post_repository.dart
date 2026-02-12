import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../entities/post.dart';
import '../entities/comment.dart';

abstract class PostRepository {
  // Posts
  Future<Either<Failure, PaginatedResponse<Post>>> getPosts({int limit = 20, int offset = 0});
  Future<Either<Failure, Post>> getPostById(String postId);
  Future<Either<Failure, Post>> createPost(Post post);
  Future<Either<Failure, Post>> updatePost(Post post);
  Future<Either<Failure, void>> deletePost(String postId);

  // Likes
  Future<Either<Failure, Post>> likePost(String postId);
  Future<Either<Failure, Post>> unlikePost(String postId);

  // Reposts
  Future<Either<Failure, Post>> repostPost(String postId, {String? quoteContent});
  Future<Either<Failure, void>> undoRepost(String postId);

  // Bookmarks
  Future<Either<Failure, Post>> bookmarkPost(String postId);
  Future<Either<Failure, Post>> unbookmarkPost(String postId);
  Future<Either<Failure, List<Post>>> getBookmarkedPosts({int limit = 20, int offset = 0});

  // Comments
  Future<Either<Failure, PaginatedResponse<Comment>>> getComments(String postId, {int limit = 20, int offset = 0});
  Future<Either<Failure, Comment>> createComment(Comment comment);
  Future<Either<Failure, Comment>> updateComment(Comment comment);
  Future<Either<Failure, Comment>> likeComment(String postId, String commentId);
  Future<Either<Failure, Comment>> unlikeComment(String postId, String commentId);
  Future<Either<Failure, void>> deleteComment(String commentId);

  // Feed
  Future<Either<Failure, PaginatedResponse<Post>>> getFeedPosts({int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResponse<Post>>> getUserPosts(String userId, {int limit = 20, int offset = 0});

  // Share
  Future<Either<Failure, void>> sharePost(String postId);
}
