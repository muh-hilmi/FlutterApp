import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/event_model.dart';
import '../../../core/utils/logger.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents({String? mode});
  Future<List<EventModel>> getEventsByCategory(String category);
  Future<EventModel> getEventById(String id);
  Future<EventModel> createEvent(Map<String, dynamic> eventData);
  Future<EventModel> updateEvent(String id, Map<String, dynamic> eventData);
  Future<void> deleteEvent(String id);

  Future<void> joinEvent(String eventId);
  Future<void> leaveEvent(String eventId);
  Future<List<EventModel>> getMyEvents();
  Future<List<EventModel>> getMyHostedEvents();
  Future<List<EventModel>> getJoinedEvents({int limit = 20, int offset = 0});

  /// Get event attendees for host view
  Future<List<Map<String, dynamic>>> getEventAttendees(
    String eventId, {
    String? status,
    String? search,
  });

  /// Check in attendee to event
  Future<Map<String, dynamic>> checkInAttendee({
    required String eventId,
    required String userId,
    required String ticketId,
  });

  Future<List<EventModel>> getUserEventsByUsername(
    String username, {
    int limit = 20,
    int offset = 0,
  });
  Future<Map<String, dynamic>?> toggleInterest(String eventId);

  Future<List<EventModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
    int offset = 0,
  });

  Future<String> uploadImage(File file);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final DioClient dioClient;

  EventRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<EventModel>> getEvents({String? mode}) async {
    try {
      logger.d('[EventRemoteDataSource] Fetching events with mode: $mode');
      final queryParams = mode != null ? {'mode': mode} : null;
      final response = await dioClient.get(
        '/events',
        queryParameters: queryParams,
      );
      logger.d(
        '[EventRemoteDataSource] Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        logger.d('[EventRemoteDataSource] ===== MODE: $mode =====');
        logger.d('[EventRemoteDataSource] Received ${data.length} events');

        final events = <EventModel>[];
        for (int i = 0; i < data.length; i++) {
          try {
            final event = EventModel.fromJson(data[i]);
            events.add(event);
            // Log first 5 events to see ordering
            if (i < 5) {
              logger.d(
                '[EventRemoteDataSource] #${i + 1}: ${event.title} (${event.currentAttendees} attendees)',
              );
            }
          } catch (e) {
            logger.e('[EventRemoteDataSource] Error parsing event $i: $e');
            logger.d('[EventRemoteDataSource] Event data: ${data[i]}');
            // Skip malformed events but continue parsing others
          }
        }

        logger.d(
          '[EventRemoteDataSource] Successfully parsed ${events.length} events',
        );
        logger.d('[EventRemoteDataSource] ===========================');
        return events;
      } else {
        throw ServerFailure('Failed to fetch events');
      }
    } on DioException catch (e) {
      logger.e(
        '[EventRemoteDataSource] DioException: ${e.response?.statusCode} - ${e.message}',
      );
      logger.d('[EventRemoteDataSource] Response data: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      logger.e('[EventRemoteDataSource] Unexpected error: $e');
      logger.d('[EventRemoteDataSource] Stack trace: $stackTrace');
      throw ServerFailure('Unexpected error while fetching events: $e');
    }
  }

  @override
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      logger.d(
        '[EventRemoteDataSource] Fetching events by category: $category',
      );
      final response = await dioClient.get(
        '/events',
        queryParameters: {'category': category},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        logger.d(
          '[EventRemoteDataSource] Received ${data.length} events for category $category',
        );
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch events by category');
      }
    } on DioException catch (e) {
      logger.e(
        '[EventRemoteDataSource] DioException category: ${e.response?.statusCode} - ${e.message}',
      );
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      logger.e(
        '[EventRemoteDataSource] Unexpected error in getEventsByCategory: $e',
      );
      logger.d('[EventRemoteDataSource] Stack trace: $stackTrace');
      throw ServerFailure(
        'Unexpected error while fetching events by category: $e',
      );
    }
  }

  @override
  Future<EventModel> getEventById(String id) async {
    try {
      final response = await dioClient.get('/events/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data == null || data is! Map<String, dynamic>) {
          throw ServerFailure('Invalid event data response');
        }
        return EventModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to fetch event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<EventModel> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await dioClient.post('/events', data: eventData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return EventModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to create event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<EventModel> updateEvent(
    String id,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await dioClient.put('/events/$id', data: eventData);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return EventModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to update event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      final response = await dioClient.delete('/events/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to delete event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> joinEvent(String eventId) async {
    try {
      final response = await dioClient.post('/events/$eventId/join');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to join event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> leaveEvent(String eventId) async {
    try {
      final response = await dioClient.delete('/events/$eventId/join');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to leave event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getMyEvents() async {
    try {
      final response = await dioClient.get('/events/my-events');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch my events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getMyHostedEvents() async {
    try {
      final response = await dioClient.get('/events/hosted');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch hosted events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getJoinedEvents({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        '/events/joined',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch joined events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEventAttendees(
    String eventId, {
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }
      if (search != null) {
        queryParams['search'] = search;
      }

      final response = await dioClient.get(
        '/events/$eventId/attendees',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw ServerFailure('Failed to fetch event attendees');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> checkInAttendee({
    required String eventId,
    required String userId,
    required String ticketId,
  }) async {
    try {
      final response = await dioClient.post(
        '/events/$eventId/check-in',
        data: {'user_id': userId, 'ticket_id': ticketId},
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw ServerFailure('Failed to check in attendee');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>?> toggleInterest(String eventId) async {
    try {
      final response = await dioClient.post('/events/$eventId/interest');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to toggle event interest');
      }

      // API returns: {success: true, data: {interest_count: X, is_interested: bool}}
      logger.d(
        '[EventRemoteDataSource] Toggle interest response: ${response.data}',
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }

      return null;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getUserEventsByUsername(
    String username, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      logger.d('[EventRemoteDataSource] Fetching events for user: $username');
      final response = await dioClient.get(
        '/profile/$username/events',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        logger.d(
          '[EventRemoteDataSource] Response type: ${response.data['data'].runtimeType}',
        );
        // Backend might return: { data: { events: [...] } } or { data: [...] }
        final responseData = response.data['data'];
        final List<dynamic> data = responseData is List
            ? responseData
            : (responseData?['events'] ?? []);
        logger.d('[EventRemoteDataSource] Found ${data.length} events');
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch user events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      logger.d(
        '[EventRemoteDataSource] Fetching nearby events: lat=$latitude, lng=$longitude, radius=$radiusKm',
      );
      final response = await dioClient.get(
        '/events/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km':
              radiusKm, // Backend expects snake_case probably? Keep param string as snake_case if API requires it.
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        logger.d('[EventRemoteDataSource] Found ${data.length} nearby events');
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch nearby events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<String> uploadImage(File file) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await dioClient.post(
        '/upload/image',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        logger.d('[EventRemoteDataSource] Upload response data: $data');

        // Handle various response structures
        if (data != null) {
          if (data is Map && data['url'] != null) {
            return data['url'] as String;
          } else if (data is String) {
            // Sometimes it might just return the string directly (?) or full object
            return data;
          } else if (data is Map && data['file_url'] != null) {
            return data['file_url'] as String;
          }
          // Fallback: check nested 'data' again (common wrapped response issue)
          else if (data is Map &&
              data['data'] != null &&
              data['data']['url'] != null) {
            return data['data']['url'] as String;
          }
        }

        // If we reach here, we couldn't find the URL
        throw ServerFailure(
          'Invalid upload response format: Missing URL in $data',
        );
      } else {
        throw ServerFailure('Failed to upload image: ${response.statusCode}');
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
