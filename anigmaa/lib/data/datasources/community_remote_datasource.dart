import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/community_model.dart';
import '../../core/utils/logger.dart';

abstract class CommunityRemoteDataSource {
  Future<List<CommunityModel>> getCommunities({
    String? search,
    String? privacy,
    int limit = 20,
    int offset = 0,
  });
  Future<CommunityModel> getCommunityById(String id);
  Future<CommunityModel> createCommunity(Map<String, dynamic> communityData);
  Future<CommunityModel> updateCommunity(String id, Map<String, dynamic> communityData);
  Future<void> deleteCommunity(String id);
  Future<void> joinCommunity(String communityId);
  Future<void> leaveCommunity(String communityId);
  Future<List<Map<String, dynamic>>> getCommunityMembers(String communityId, {int limit = 20, int offset = 0});
  Future<List<CommunityModel>> getMyCommunities({int limit = 20, int offset = 0});
}

class CommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final DioClient dioClient;

  CommunityRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CommunityModel>> getCommunities({
    String? search,
    String? privacy,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      logger.d('[CommunityRemoteDataSource] Fetching communities...');
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (privacy != null && privacy.isNotEmpty) {
        queryParams['privacy'] = privacy;
      }

      final response = await dioClient.get(
        '/communities',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.i('[CommunityRemoteDataSource] Received ${data.length} communities');
        return data.map((json) => CommunityModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch communities');
      }
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error fetching communities: ${e.response?.statusCode}');

      // If backend has issues, return empty list instead of crashing
      if (e.response?.statusCode == 500) {
        logger.w('[CommunityRemoteDataSource] Backend error (500) - returning empty list');
        return [];
      }

      throw _handleDioException(e);
    } catch (e) {
      logger.e('[CommunityRemoteDataSource] Unexpected error: $e');
      return [];
    }
  }

  @override
  Future<CommunityModel> getCommunityById(String id) async {
    try {
      logger.d('[CommunityRemoteDataSource] Fetching community: $id');
      final response = await dioClient.get('/communities/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        logger.i('[CommunityRemoteDataSource] Community retrieved successfully');
        return CommunityModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to fetch community');
      }
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error fetching community: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<CommunityModel> createCommunity(Map<String, dynamic> communityData) async {
    try {
      logger.d('[CommunityRemoteDataSource] Creating community...');
      final response = await dioClient.post(
        '/communities',
        data: communityData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        logger.i('[CommunityRemoteDataSource] Community created successfully');
        return CommunityModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to create community');
      }
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error creating community: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<CommunityModel> updateCommunity(String id, Map<String, dynamic> communityData) async {
    try {
      logger.d('[CommunityRemoteDataSource] Updating community: $id');
      final response = await dioClient.put(
        '/communities/$id',
        data: communityData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        logger.i('[CommunityRemoteDataSource] Community updated successfully');
        return CommunityModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to update community');
      }
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error updating community: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteCommunity(String id) async {
    try {
      logger.d('[CommunityRemoteDataSource] Deleting community: $id');
      final response = await dioClient.delete('/communities/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to delete community');
      }

      logger.i('[CommunityRemoteDataSource] Community deleted successfully');
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error deleting community: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> joinCommunity(String communityId) async {
    try {
      logger.d('[CommunityRemoteDataSource] Joining community: $communityId');
      final response = await dioClient.post('/communities/$communityId/join');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to join community');
      }

      logger.i('[CommunityRemoteDataSource] Joined community successfully');
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error joining community: ${e.response?.statusCode}');

      // If already joined (409 Conflict), treat as success
      if (e.response?.statusCode == 409) {
        logger.w('[CommunityRemoteDataSource] Already joined - treating as success');
        return;
      }

      throw _handleDioException(e);
    }
  }

  @override
  Future<void> leaveCommunity(String communityId) async {
    try {
      logger.d('[CommunityRemoteDataSource] Leaving community: $communityId');
      final response = await dioClient.delete('/communities/$communityId/leave');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to leave community');
      }

      logger.i('[CommunityRemoteDataSource] Left community successfully');
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error leaving community: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCommunityMembers(
    String communityId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      logger.d('[CommunityRemoteDataSource] Getting members for community: $communityId');
      final response = await dioClient.get(
        '/communities/$communityId/members',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.i('[CommunityRemoteDataSource] Found ${data.length} members');
        return data.map((json) => Map<String, dynamic>.from(json)).toList();
      } else {
        throw ServerFailure('Failed to get community members');
      }
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error getting members: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<CommunityModel>> getMyCommunities({int limit = 20, int offset = 0}) async {
    try {
      logger.d('[CommunityRemoteDataSource] Getting my communities...');
      final response = await dioClient.get(
        '/communities/my-communities',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        logger.i('[CommunityRemoteDataSource] Found ${data.length} communities');
        return data.map((json) => CommunityModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to get my communities');
      }
    } on DioException catch (e) {
      logger.e('[CommunityRemoteDataSource] Error getting my communities: ${e.response?.statusCode}');

      // If backend has issues, return empty list instead of crashing
      if (e.response?.statusCode == 500) {
        logger.w('[CommunityRemoteDataSource] Backend error (500) - returning empty list');
        return [];
      }

      throw _handleDioException(e);
    } catch (e) {
      logger.e('[CommunityRemoteDataSource] Unexpected error: $e');
      return [];
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
