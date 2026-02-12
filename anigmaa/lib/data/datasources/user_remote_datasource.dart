import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/user_model.dart';
import '../../core/utils/logger.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Future<UserModel> getUserById(String userId);
  Future<UserModel> updateCurrentUser(Map<String, dynamic> userData);
  Future<void> updateUserSettings(Map<String, dynamic> settings);
  Future<void> deleteAccount();
  Future<List<UserModel>> searchUsers(
    String query, {
    int limit = 20,
    int offset = 0,
  });
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
  Future<List<UserModel>> getUserFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  });
  Future<List<UserModel>> getUserFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  });
  Future<Map<String, dynamic>> getUserStats(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final DioClient dioClient;

  UserRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      logger.d('[UserRemoteDataSource] Getting current user...');
      final response = await dioClient.get('/users/me');

      if (response.statusCode == 200) {
        // Backend returns: { data: { user: {...}, stats: {...}, settings: {...} } }
        final profileData = response.data['data'] ?? response.data;

        // Merge user with stats, settings, privacy for complete profile
        final userData = Map<String, dynamic>.from(
          profileData['user'] ?? profileData,
        );
        final statsData = profileData['stats'] ?? userData['stats'] ?? {};
        final settingsData =
            profileData['settings'] ?? userData['settings'] ?? {};
        final privacyData = profileData['privacy'] ?? userData['privacy'] ?? {};

        // Create merged JSON with all data
        final mergedData = Map<String, dynamic>.from(userData)
          ..addAll({
            if (statsData.isNotEmpty) 'stats': statsData,
            if (settingsData.isNotEmpty) 'settings': settingsData,
            if (privacyData.isNotEmpty) 'privacy': privacyData,
          });

        logger.i('[UserRemoteDataSource] Current user retrieved successfully');
        return UserModel.fromJson(mergedData);
      } else {
        throw ServerFailure('Failed to get current user');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error getting current user: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      logger.d('[UserRemoteDataSource] Getting user by ID: $userId');
      final response = await dioClient.get('/users/$userId');

      if (response.statusCode == 200) {
        // Backend returns: { data: { user: {...}, settings: {...}, stats: {...}, privacy: {...}, is_following: bool } }
        final profileData = response.data['data'] ?? response.data;

        // Merge user with stats, settings, privacy for complete profile
        final userData = Map<String, dynamic>.from(
          profileData['user'] ?? profileData,
        );
        final statsData = profileData['stats'] ?? userData['stats'] ?? {};
        final settingsData =
            profileData['settings'] ?? userData['settings'] ?? {};
        final privacyData = profileData['privacy'] ?? userData['privacy'] ?? {};

        // is_following might be at top level of profileData or inside userData
        final isFollowing =
            profileData['is_following'] ?? userData['is_following'];

        // Create merged JSON with all data
        // Priority: profileData fields > userData fields
        final mergedData = Map<String, dynamic>.from(userData)
          ..addAll({
            if (statsData.isNotEmpty) 'stats': statsData,
            if (settingsData.isNotEmpty) 'settings': settingsData,
            if (privacyData.isNotEmpty) 'privacy': privacyData,
            'is_following': isFollowing,
          });

        logger.i(
          '[UserRemoteDataSource] User retrieved successfully, ID: ${mergedData['id']}, is_following: $isFollowing',
        );
        return UserModel.fromJson(mergedData);
      } else {
        throw ServerFailure('Failed to get user');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error getting user: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> updateCurrentUser(Map<String, dynamic> userData) async {
    try {
      logger.d('[UserRemoteDataSource] Updating current user with PATCH...');
      final response = await dioClient.patch('/users/me', data: userData);

      if (response.statusCode == 200) {
        // Backend returns: { data: { user: {...} } }
        final data =
            response.data['data']?['user'] ??
            response.data['data'] ??
            response.data;
        logger.i('[UserRemoteDataSource] User updated successfully');
        return UserModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to update user');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error updating user: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      logger.d('[UserRemoteDataSource] Updating user settings...');
      final response = await dioClient.put(
        '/users/me/settings',
        data: settings,
      );

      if (response.statusCode != 200) {
        throw ServerFailure('Failed to update user settings');
      }

      logger.i('[UserRemoteDataSource] Settings updated successfully');
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error updating settings: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<UserModel>> searchUsers(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      logger.d('[UserRemoteDataSource] Searching users: $query');
      final response = await dioClient.get(
        '/users/search',
        queryParameters: {'q': query, 'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.i('[UserRemoteDataSource] Found ${data.length} users');
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to search users');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error searching users: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> followUser(String userId) async {
    try {
      logger.d('[UserRemoteDataSource] Following user: $userId');
      final response = await dioClient.post('/users/$userId/follow');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to follow user');
      }

      logger.i('[UserRemoteDataSource] User followed successfully');
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error following user: ${e.response?.statusCode}',
      );

      // If already following (409 Conflict), treat as success
      if (e.response?.statusCode == 409) {
        logger.w(
          '[UserRemoteDataSource] Already following - treating as success',
        );
        return;
      }

      throw _handleDioException(e);
    }
  }

  @override
  Future<void> unfollowUser(String userId) async {
    try {
      logger.d('[UserRemoteDataSource] Unfollowing user: $userId');
      final response = await dioClient.delete('/users/$userId/follow');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to unfollow user');
      }

      logger.i('[UserRemoteDataSource] User unfollowed successfully');
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error unfollowing user: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<UserModel>> getUserFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      logger.d('[UserRemoteDataSource] Getting followers for user: $userId');
      final response = await dioClient.get(
        '/users/$userId/followers',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.i('[UserRemoteDataSource] Found ${data.length} followers');
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to get followers');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error getting followers: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<UserModel>> getUserFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      logger.d('[UserRemoteDataSource] Getting following for user: $userId');
      final response = await dioClient.get(
        '/users/$userId/following',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.i('[UserRemoteDataSource] Found ${data.length} following');
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to get following');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error getting following: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      logger.d('[UserRemoteDataSource] Getting stats for user: $userId');
      final response = await dioClient.get('/users/$userId/stats');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        logger.i('[UserRemoteDataSource] Stats retrieved successfully');
        return Map<String, dynamic>.from(data);
      } else {
        throw ServerFailure('Failed to get user stats');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error getting stats: ${e.response?.statusCode}',
      );
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      logger.d('[UserRemoteDataSource] Deleting account...');
      final response = await dioClient.delete('/users/me');

      if (response.statusCode == 200) {
        logger.i('[UserRemoteDataSource] Account deleted successfully');
        return;
      } else {
        throw ServerFailure('Failed to delete account');
      }
    } on DioException catch (e) {
      logger.e(
        '[UserRemoteDataSource] Error deleting account: ${e.response?.statusCode}',
      );
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
