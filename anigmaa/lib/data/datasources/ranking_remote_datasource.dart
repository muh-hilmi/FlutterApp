import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/ranked_feed_model.dart';
import '../../core/utils/logger.dart';

abstract class RankingRemoteDataSource {
  Future<RankedFeedModel> getRankedFeed(RankingRequestModel request);
}

class RankingRemoteDataSourceImpl implements RankingRemoteDataSource {
  final DioClient dioClient;

  RankingRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<RankedFeedModel> getRankedFeed(RankingRequestModel request) async {
    try {
      // Uncomment for debugging:
      // logger.d('[RankingRemoteDataSource] Sending ranking request...');
      // logger.d('[RankingRemoteDataSource] Posts: ${request.posts.length}, Events: ${request.events.length}');

      final response = await dioClient.post(
        '/feed/rank',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return RankedFeedModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to rank feed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      logger.e('[RankingRemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to rank feed: $e');
    }
  }

  Failure _handleDioException(DioException e) {
    // Only log on actual errors
    if (e.type != DioExceptionType.cancel) {
      logger.e('[RankingRemoteDataSource] Error: ${e.type} - ${e.message}');
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Unknown error';
        if (statusCode == 401) {
          return UnauthorizedFailure('Unauthorized');
        } else if (statusCode == 404) {
          return NotFoundFailure('Ranking endpoint not found');
        } else if (statusCode == 400) {
          return ValidationFailure(message);
        }
        return ServerFailure('Server error: $message');
      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return NetworkFailure('Network error: ${e.message}');
      default:
        return ServerFailure('Unknown error: ${e.message}');
    }
  }
}
