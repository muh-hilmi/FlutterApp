import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/post_model.dart';
import '../../domain/entities/comment.dart';
import '../../core/utils/logger.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getPosts({int limit = 20, int offset = 0});
  Future<List<PostModel>> getPostsByUser(String userId, {int page = 1, int limit = 20});
  Future<PostModel> getPostById(String id);
  Future<PostModel> createPost(Map<String, dynamic> postData);
  Future<PostModel> updatePost(String id, Map<String, dynamic> postData);
  Future<void> deletePost(String id);
  Future<void> likePost(String postId);
  Future<void> unlikePost(String postId);
  Future<PostModel> repostPost(String postId, {String? comment});
  Future<void> undoRepost(String postId);
  Future<void> bookmarkPost(String postId);
  Future<void> unbookmarkPost(String postId);
  Future<List<PostModel>> getBookmarkedPosts({int limit = 20, int offset = 0});
  Future<List<Comment>> getPostComments(String postId, {int page = 1, int limit = 20});
  Future<Comment> createComment(String postId, Map<String, dynamic> commentData);
  Future<Comment> updateComment(String commentId, Map<String, dynamic> commentData);
  Future<void> deleteComment(String commentId);
  Future<void> likeComment(String postId, String commentId);
  Future<void> unlikeComment(String postId, String commentId);
  Future<void> voteOnPoll(String postId, String pollId, String optionId);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final DioClient dioClient;

  PostRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<PostModel>> getPosts({int limit = 20, int offset = 0}) async {
    try {
      final response = await dioClient.get(
        '/posts/feed',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.d('[PostRemoteDataSource] Parsing ${data.length} posts...');

        final posts = <PostModel>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final postData = data[i];
            // Check if post has attached event
            if (postData['attached_event'] != null || postData['attachedEvent'] != null) {
              logger.d('[PostRemoteDataSource] Post $i has attached event');
            }
            final post = PostModel.fromJson(postData);
            posts.add(post);
          } catch (e, stackTrace) {
            logger.e('[PostRemoteDataSource] Failed to parse post $i: $e');
            logger.e('[PostRemoteDataSource] Post data: ${data[i]}');
            logger.d('[PostRemoteDataSource] Stack trace: $stackTrace');
            // Continue parsing other posts instead of failing completely
          }
        }

        logger.i('[PostRemoteDataSource] Successfully parsed ${posts.length} posts');
        return posts;
      } else {
        throw ServerFailure('Failed to fetch posts');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<PostModel>> getPostsByUser(String userId, {int page = 1, int limit = 20}) async {
    try {
      // Get posts by user ID (backend endpoint: /users/{userId}/posts)
      logger.d('[PostRemoteDataSource] Fetching posts for user: $userId');
      final offset = (page - 1) * limit;
      final response = await dioClient.get(
        '/users/$userId/posts',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      logger.d('[PostRemoteDataSource] Response status: ${response.statusCode}');
      logger.d('[PostRemoteDataSource] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.d('[PostRemoteDataSource] Posts count: ${data.length}');
        return data.map((json) => PostModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch user posts');
      }
    } on DioException catch (e) {
      logger.e('[PostRemoteDataSource] DioException: ${e.message}');
      logger.e('[PostRemoteDataSource] Response: ${e.response?.data}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<PostModel> getPostById(String id) async {
    try {
      final response = await dioClient.get('/posts/$id');

      if (response.statusCode == 200) {
        // Check if data field exists and is not null
        if (response.data['data'] == null) {
          logger.e('[PostRemoteDataSource] Backend returned null data for post $id');
          logger.e('[PostRemoteDataSource] Response: ${response.data}');
          throw ServerFailure('Post not found - backend returned null data');
        }

        final data = response.data['data'];

        // Additional validation
        if (data is! Map) {
          logger.e('[PostRemoteDataSource] Data is not a Map: $data');
          throw ServerFailure('Invalid post data format');
        }

        return PostModel.fromJson(Map<String, dynamic>.from(data));
      } else {
        throw ServerFailure('Failed to fetch post');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<PostModel> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await dioClient.post(
        '/posts',
        data: postData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return PostModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to create post');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<PostModel> updatePost(String id, Map<String, dynamic> postData) async {
    try {
      final response = await dioClient.put(
        '/posts/$id',
        data: postData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return PostModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to update post');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deletePost(String id) async {
    try {
      final response = await dioClient.delete('/posts/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to delete post');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> likePost(String postId) async {
    try {
      logger.d('[PostRemoteDataSource] Liking post $postId...');
      final response = await dioClient.post('/posts/$postId/like');
      logger.d('[PostRemoteDataSource] Like response status: ${response.statusCode}');
      logger.d('[PostRemoteDataSource] Like response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('[PostRemoteDataSource] Like successful');
      } else if (response.statusCode == 409) {
        // 409 = already liked on server — the post IS liked, not an error
        logger.w('[PostRemoteDataSource] Post already liked (409) - treating as success');
      } else {
        throw ServerFailure('Failed to like post');
      }
    } on DioException catch (e) {
      logger.e('[PostRemoteDataSource] Like error: ${e.message}');

      // If post is already liked via DioException path, treat as success
      if ((e.response?.statusCode == 400 || e.response?.statusCode == 409) &&
          e.response?.data?['message']?.toString().toLowerCase().contains('already liked') == true) {
        logger.w('[PostRemoteDataSource] Post already liked - treating as success');
        return;
      }

      throw _handleDioException(e);
    }
  }

  @override
  Future<void> unlikePost(String postId) async {
    try {
      logger.d('[PostRemoteDataSource] Unliking post $postId...');
      final response = await dioClient.post('/posts/$postId/unlike');
      logger.d('[PostRemoteDataSource] Unlike response status: ${response.statusCode}');
      logger.d('[PostRemoteDataSource] Unlike response data: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
        throw ServerFailure('Failed to unlike post');
      }

      logger.i('[PostRemoteDataSource] Unlike successful');
    } on DioException catch (e) {
      logger.e('[PostRemoteDataSource] Unlike error: ${e.message}');

      // If post is already not liked (400 or 409 with "Post not liked"), treat as success
      if ((e.response?.statusCode == 400 || e.response?.statusCode == 409) &&
          e.response?.data?['message']?.toString().toLowerCase().contains('not liked') == true) {
        logger.w('[PostRemoteDataSource] Post already not liked - treating as success');
        return;
      }

      throw _handleDioException(e);
    }
  }

  @override
  Future<PostModel> repostPost(String postId, {String? comment}) async {
    try {
      final response = await dioClient.post(
        '/posts/repost',
        data: {
          'post_id': postId,
          if (comment != null) 'quote_content': comment,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return PostModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to repost');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> undoRepost(String postId) async {
    try {
      final response = await dioClient.post('/posts/$postId/undo-repost');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to undo repost');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> bookmarkPost(String postId) async {
    try {
      logger.d('[PostRemoteDataSource] Bookmarking post: $postId');
      final response = await dioClient.post('/posts/$postId/bookmark');
      logger.d('[PostRemoteDataSource] Bookmark response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to bookmark post');
      }
      logger.i('[PostRemoteDataSource] Post bookmarked successfully');
    } on DioException catch (e) {
      logger.e('[PostRemoteDataSource] Error bookmarking post: ${e.response?.statusCode} - ${e.message}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> unbookmarkPost(String postId) async {
    try {
      final response = await dioClient.delete('/posts/$postId/bookmark');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to unbookmark post');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<PostModel>> getBookmarkedPosts({int limit = 20, int offset = 0}) async {
    try {
      final response = await dioClient.get(
        '/posts/bookmarks',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.d('[PostRemoteDataSource] Parsing ${data.length} bookmarked posts...');

        final posts = <PostModel>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final post = PostModel.fromJson(data[i]);
            posts.add(post);
          } catch (e, stackTrace) {
            logger.e('[PostRemoteDataSource] Failed to parse bookmarked post $i: $e');
            logger.d('[PostRemoteDataSource] Stack trace: $stackTrace');
            // Continue parsing other posts instead of failing completely
          }
        }

        logger.i('[PostRemoteDataSource] Successfully parsed ${posts.length} bookmarked posts');
        return posts;
      } else {
        throw ServerFailure('Failed to fetch bookmarked posts');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Comment>> getPostComments(String postId, {int page = 1, int limit = 20}) async {
    try {
      // Convert page to offset (page 1 = offset 0)
      final offset = (page - 1) * limit;
      final response = await dioClient.get(
        '/posts/$postId/comments',
        queryParameters: {'offset': offset, 'limit': limit},
      );

      if (response.statusCode == 200) {
        // Handle different response structures
        final responseData = response.data;

        // Check if data field exists and is a list
        if (responseData['data'] != null) {
          if (responseData['data'] is List) {
            final List<dynamic> data = responseData['data'];
            return data.map((json) => Comment.fromJson(json)).toList();
          } else if (responseData['data'] is Map && (responseData['data'] as Map).isEmpty) {
            // Empty map means no comments
            return [];
          }
        }

        // Check if response itself is a list
        if (responseData is List) {
          return responseData.map((json) => Comment.fromJson(json)).toList();
        }

        // If we get here, API returned unexpected structure - return empty list
        logger.w('[PostRemoteDataSource] Unexpected comments response structure: $responseData');
        return [];
      } else {
        throw ServerFailure('Failed to fetch comments');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Comment> createComment(String postId, Map<String, dynamic> commentData) async {
    try {
      // Add post_id to the comment data
      final data = {
        ...commentData,
        'post_id': postId,
      };

      final response = await dioClient.post(
        '/posts/comments',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data['data'] ?? response.data;
        return Comment.fromJson(responseData);
      } else {
        throw ServerFailure('Failed to create comment');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Comment> updateComment(String commentId, Map<String, dynamic> commentData) async {
    try {
      final response = await dioClient.put(
        '/posts/comments/$commentId',
        data: commentData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'] ?? response.data;
        return Comment.fromJson(responseData);
      } else {
        throw ServerFailure('Failed to update comment');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await dioClient.delete('/posts/comments/$commentId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to delete comment');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> likeComment(String postId, String commentId) async {
    try {
      logger.d('[PostRemoteDataSource] Liking comment $commentId on post $postId...');
      final response = await dioClient.post('/posts/$postId/comments/$commentId/like');
      logger.d('[PostRemoteDataSource] Like comment response status: ${response.statusCode}');
      logger.d('[PostRemoteDataSource] Like comment response data: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to like comment');
      }

      logger.i('[PostRemoteDataSource] Like comment successful');
    } on DioException catch (e) {
      logger.e('[PostRemoteDataSource] Like comment error: ${e.message}');

      // If comment is already liked, treat as success
      if (e.response?.statusCode == 400 &&
          e.response?.data?['message']?.toString().toLowerCase().contains('already liked') == true) {
        logger.w('[PostRemoteDataSource] Comment already liked - treating as success');
        return;
      }

      throw _handleDioException(e);
    }
  }

  @override
  Future<void> unlikeComment(String postId, String commentId) async {
    try {
      logger.d('[PostRemoteDataSource] Unliking comment $commentId on post $postId...');
      final response = await dioClient.post('/posts/$postId/comments/$commentId/unlike');
      logger.d('[PostRemoteDataSource] Unlike comment response status: ${response.statusCode}');
      logger.d('[PostRemoteDataSource] Unlike comment response data: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
        throw ServerFailure('Failed to unlike comment');
      }

      logger.i('[PostRemoteDataSource] Unlike comment successful');
    } on DioException catch (e) {
      logger.e('[PostRemoteDataSource] Unlike comment error: ${e.message}');

      // If comment is already not liked, treat as success
      if (e.response?.statusCode == 400 &&
          e.response?.data?['message']?.toString().toLowerCase().contains('not liked') == true) {
        logger.w('[PostRemoteDataSource] Comment already not liked - treating as success');
        return;
      }

      throw _handleDioException(e);
    }
  }

  @override
  Future<void> voteOnPoll(String postId, String pollId, String optionId) async {
    try {
      final response = await dioClient.post(
        '/posts/$postId/polls/$pollId/vote',
        data: {'optionId': optionId},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to vote on poll');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Failure _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Server error';
        if (statusCode == 401) {
          return AuthenticationFailure(message);
        } else if (statusCode == 403) {
          return AuthorizationFailure(message);
        } else if (statusCode == 404) {
          return NotFoundFailure(message);
        } else {
          return ServerFailure(message);
        }
      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection');
      default:
        return ServerFailure('Unexpected error occurred');
    }
  }
}
