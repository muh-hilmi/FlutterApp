import 'package:dio/dio.dart';
import '../models/analytics_model.dart';

class AnalyticsService {
  final Dio _dio;
  final String _baseUrl;

  AnalyticsService(this._dio, this._baseUrl);

  /// Get comprehensive analytics for a specific event (host only)
  Future<EventAnalyticsModel> getEventAnalytics(String eventId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/analytics/events/$eventId',
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return EventAnalyticsModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load analytics');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('You are not authorized to view this event analytics');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Event not found');
      }
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  /// Get detailed transaction list for an event (host only)
  Future<List<TransactionDetailModel>> getEventTransactions(
    String eventId, {
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/analytics/events/$eventId/transactions',
        queryParameters: {
          if (status != null) 'status': status,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => TransactionDetailModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load transactions');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception(
            'You are not authorized to view this event transactions');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Event not found');
      }
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  /// Get revenue summary for all events created by the host
  Future<HostRevenueSummaryModel> getHostRevenueSummary({
    String period = 'all',
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/analytics/host/revenue',
        queryParameters: {'period': period},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return HostRevenueSummaryModel.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load revenue summary');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  /// Get list of events with revenue information
  Future<List<EventRevenueSummaryModel>> getHostEventsList({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/analytics/host/events',
        queryParameters: {
          if (status != null) 'status': status,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => EventRevenueSummaryModel.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load events');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}
