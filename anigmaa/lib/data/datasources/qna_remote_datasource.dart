import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/qna.dart';
import '../../core/utils/logger.dart';

abstract class QnARemoteDataSource {
  Future<List<QnA>> getEventQnA(String eventId);
  Future<QnA> askQuestion(String eventId, String question);
  Future<QnA> answerQuestion(String questionId, String answer);
  Future<void> upvoteQuestion(String questionId);
  Future<void> removeUpvote(String questionId);
  Future<void> deleteQuestion(String questionId);
}

class QnARemoteDataSourceImpl implements QnARemoteDataSource {
  final DioClient dioClient;

  QnARemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<QnA>> getEventQnA(String eventId) async {
    try {
      logger.d('[QnARemoteDataSource] Fetching Q&A for event $eventId...');
      final response = await dioClient.get('/events/$eventId/qna');
      logger.d('[QnARemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response structures
        if (responseData['data'] != null) {
          if (responseData['data'] is List) {
            final List<dynamic> data = responseData['data'];
            logger.i('[QnARemoteDataSource] Received ${data.length} questions');
            return data.map((json) => QnA.fromJson(json)).toList();
          } else if (responseData['data'] == null) {
            // data is null, return empty list
            logger.w('[QnARemoteDataSource] No Q&A data available');
            return [];
          }
        }

        // If response itself is a list
        if (responseData is List) {
          return responseData.map((json) => QnA.fromJson(json)).toList();
        }

        // Unexpected structure
        logger.w('[QnARemoteDataSource] Unexpected Q&A response structure: $responseData');
        return [];
      }

      throw ServerFailure('Failed to get Q&A');
    } on DioException catch (e) {
      logger.e('[QnARemoteDataSource] DioException: ${e.message}');

      // Handle 404 - endpoint not found, return empty list instead of error
      if (e.response?.statusCode == 404) {
        logger.w('[QnARemoteDataSource] Q&A endpoint not found (404) - returning empty list');
        return [];
      }

      throw _handleDioException(e);
    } catch (e) {
      logger.e('[QnARemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to get Q&A: $e');
    }
  }

  @override
  Future<QnA> askQuestion(String eventId, String question) async {
    try {
      logger.d('[QnARemoteDataSource] Asking question for event $eventId...');
      final response = await dioClient.post(
        '/events/$eventId/qna',
        data: {'question': question},
      );
      logger.d('[QnARemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return QnA.fromJson(data);
      }

      throw ServerFailure('Failed to ask question');
    } on DioException catch (e) {
      logger.e('[QnARemoteDataSource] DioException: ${e.message}');

      // Handle 404 - endpoint not found
      if (e.response?.statusCode == 404) {
        logger.w('[QnARemoteDataSource] Q&A endpoint not found (404)');
        throw ServerFailure('Q&A feature is not available yet');
      }

      throw _handleDioException(e);
    } catch (e) {
      logger.e('[QnARemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to ask question: $e');
    }
  }

  @override
  Future<QnA> answerQuestion(String questionId, String answer) async {
    try {
      logger.d('[QnARemoteDataSource] Answering question $questionId...');
      final response = await dioClient.post(
        '/qna/$questionId/answer',
        data: {'answer': answer},
      );
      logger.d('[QnARemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return QnA.fromJson(data);
      }

      throw ServerFailure('Failed to answer question');
    } on DioException catch (e) {
      logger.e('[QnARemoteDataSource] DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      logger.e('[QnARemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to answer question: $e');
    }
  }

  @override
  Future<void> upvoteQuestion(String questionId) async {
    try {
      logger.d('[QnARemoteDataSource] Upvoting question $questionId...');
      final response = await dioClient.post('/qna/$questionId/upvote');
      logger.d('[QnARemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to upvote question');
      }
    } on DioException catch (e) {
      logger.e('[QnARemoteDataSource] DioException: ${e.message}');

      // If already upvoted, treat as success
      if (e.response?.statusCode == 400 &&
          e.response?.data?['message']?.toString().toLowerCase().contains('already upvoted') == true) {
        logger.w('[QnARemoteDataSource] Question already upvoted - treating as success');
        return;
      }

      // Handle 404 - endpoint not found
      if (e.response?.statusCode == 404) {
        logger.w('[QnARemoteDataSource] Q&A endpoint not found (404)');
        throw ServerFailure('Q&A feature is not available yet');
      }

      throw _handleDioException(e);
    } catch (e) {
      logger.e('[QnARemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to upvote question: $e');
    }
  }

  @override
  Future<void> removeUpvote(String questionId) async {
    try {
      logger.d('[QnARemoteDataSource] Removing upvote from question $questionId...');
      final response = await dioClient.delete('/qna/$questionId/upvote');
      logger.d('[QnARemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to remove upvote');
      }
    } on DioException catch (e) {
      logger.e('[QnARemoteDataSource] DioException: ${e.message}');

      // If not upvoted, treat as success
      if (e.response?.statusCode == 400 &&
          e.response?.data?['message']?.toString().toLowerCase().contains('not upvoted') == true) {
        logger.w('[QnARemoteDataSource] Question not upvoted - treating as success');
        return;
      }

      throw _handleDioException(e);
    } catch (e) {
      logger.e('[QnARemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to remove upvote: $e');
    }
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    try {
      logger.d('[QnARemoteDataSource] Deleting question $questionId...');
      final response = await dioClient.delete('/qna/$questionId');
      logger.d('[QnARemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to delete question');
      }
    } on DioException catch (e) {
      logger.e('[QnARemoteDataSource] DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      logger.e('[QnARemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to delete question: $e');
    }
  }

  Failure _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return ServerFailure('Unauthorized');
        } else if (statusCode == 404) {
          return ServerFailure('Not found');
        }
        return ServerFailure(e.response?.data?['message'] ?? 'Server error');
      case DioExceptionType.cancel:
        return ServerFailure('Request cancelled');
      default:
        return ServerFailure('Network error');
    }
  }
}
