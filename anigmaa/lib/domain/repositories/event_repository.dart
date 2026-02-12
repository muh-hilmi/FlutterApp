import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../entities/event.dart';
import '../entities/event_category.dart';
import '../entities/event_attendee.dart';

abstract class EventRepository {
  Future<Either<Failure, PaginatedResponse<Event>>> getEvents({
    int limit = 20,
    int offset = 0,
    String? mode,
  });
  Future<Either<Failure, PaginatedResponse<Event>>> getEventsByCategory(
    EventCategory category, {
    int limit = 20,
    int offset = 0,
  });
  Future<Either<Failure, PaginatedResponse<Event>>> getNearbyEvents({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    int limit = 20,
    int offset = 0,
  });
  Future<Either<Failure, PaginatedResponse<Event>>> getStartingSoonEvents({
    int limit = 20,
    int offset = 0,
  });
  Future<Either<Failure, Event>> getEventById(String id);
  Future<Either<Failure, Event>> createEvent(Event event);
  Future<Either<Failure, Event>> updateEvent(Event event);
  Future<Either<Failure, void>> deleteEvent(String id);
  Future<Either<Failure, void>> joinEvent(String eventId, String userId);
  Future<Either<Failure, void>> leaveEvent(String eventId, String userId);
  Future<Either<Failure, Event>> toggleEventInterest(
    String eventId,
    String userId,
  );
  Future<Either<Failure, List<Event>>> getMyEvents({String? status});

  /// Get event attendees (host only)
  Future<Either<Failure, List<EventAttendee>>> getEventAttendees({
    required String eventId,
    String? status,
    String? search,
  });

  /// Check in an attendee to an event (host only)
  Future<Either<Failure, EventAttendee>> checkInAttendee({
    required String eventId,
    required String userId,
    required String ticketId,
  });

  Future<Either<Failure, String>> uploadImage(File file);
}
