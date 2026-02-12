import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/analytics_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<EventAnalyticsModel> getEventAnalytics(String eventId);
  Future<List<TransactionDetailModel>> getEventTransactions(
    String eventId, {
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<HostRevenueSummaryModel> getHostRevenueSummary({String period = 'all'});
  Future<List<EventRevenueSummaryModel>> getHostEvents({
    String? status,
    int limit = 20,
    int offset = 0,
  });
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final DioClient dioClient;

  AnalyticsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<EventAnalyticsModel> getEventAnalytics(String eventId) async {
    try {
      final response = await dioClient.get('/analytics/events/$eventId');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return EventAnalyticsModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to fetch event analytics');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<TransactionDetailModel>> getEventTransactions(
    String eventId, {
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        '/analytics/events/$eventId/transactions',
        queryParameters: {
          if (status != null) 'status': status,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data
            .map((json) => TransactionDetailModel.fromJson(json))
            .toList();
      } else {
        throw ServerFailure('Failed to fetch event transactions');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<HostRevenueSummaryModel> getHostRevenueSummary({
    String period = 'all',
  }) async {
    try {
      final response = await dioClient.get(
        '/analytics/host/revenue',
        queryParameters: {'period': period},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return HostRevenueSummaryModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to fetch host revenue summary');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventRevenueSummaryModel>> getHostEvents({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        '/analytics/host/events',
        queryParameters: {
          if (status != null) 'status': status,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data
            .map((json) => EventRevenueSummaryModel.fromJson(json))
            .toList();
      } else {
        throw ServerFailure('Failed to fetch host events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Handle DioException and convert to appropriate Failure
  Failure _handleDioException(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['message'] ?? e.message;

      switch (statusCode) {
        case 400:
          return BadRequestFailure(message ?? 'Bad request');
        case 401:
          return UnauthorizedFailure(message ?? 'Unauthorized');
        case 403:
          return ForbiddenFailure(
              message ?? 'You are not authorized to view this analytics');
        case 404:
          return NotFoundFailure(message ?? 'Analytics not found');
        case 422:
          return ValidationFailure(message ?? 'Validation error');
        case 500:
          return ServerFailure(message ?? 'Internal server error');
        default:
          return ServerFailure(message ?? 'Server error');
      }
    } else {
      // Connection error
      return NetworkFailure('No internet connection');
    }
  }
}
