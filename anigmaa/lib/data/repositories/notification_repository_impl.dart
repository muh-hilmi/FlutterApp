import 'package:dio/dio.dart';
import '../../domain/entities/notification.dart' as domain;
import '../../domain/repositories/notification_repository.dart';
import '../../core/api/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final DioClient _dioClient;

  NotificationRepositoryImpl(this._dioClient);

  @override
  Future<List<domain.Notification>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((notificationJson) => NotificationModel.fromJson(notificationJson))
            .map((model) => model.toEntity())
            .toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _dioClient.dio.patch(
        '/notifications/$notificationId/read',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    try {
      final response = await _dioClient.dio.patch(
        '/notifications/read-all',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _dioClient.dio.delete(
        '/notifications/$notificationId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await _dioClient.dio.get(
        '/notifications/unread-count',
      );

      if (response.statusCode == 200) {
        return response.data['count'] as int;
      } else {
        throw Exception('Failed to get unread notifications count');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 401:
            return Exception('Unauthorized');
          case 404:
            return Exception('Not found');
          case 500:
            return Exception('Server error');
          default:
            return Exception('HTTP Error: $statusCode');
        }
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.connectionError:
        return Exception('Connection error');
      case DioExceptionType.unknown:
        return Exception('Network error');
      default:
        return Exception('Unknown error');
    }
  }
}