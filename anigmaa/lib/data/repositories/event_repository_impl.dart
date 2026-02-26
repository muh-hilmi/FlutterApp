import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_location.dart';
import '../../domain/entities/event_host.dart';
import '../../domain/entities/event_attendee.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_local_datasource.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_model.dart';
import '../../core/utils/logger.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;
  final EventLocalDataSource localDataSource;

  EventRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getEvents({
    int limit = 20,
    int offset = 0,
    String? mode,
  }) async {
    try {
      // Fetch from remote only - no fallback
      final events = await remoteDataSource.getEvents(mode: mode);
      // Cache the events locally for future use
      await localDataSource.cacheEvents(events);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: events, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get events: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getEventsByCategory(
    EventCategory category, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Fetch from remote only - no fallback
      final categoryString = category.toString().split('.').last;
      final events = await remoteDataSource.getEventsByCategory(categoryString);
      // Cache the events locally
      await localDataSource.cacheEvents(events);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: events, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get events by category: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getNearbyEvents({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Use Jakarta as default location if not provided
      final lat = latitude ?? -6.2088; // Jakarta latitude
      final lng = longitude ?? 106.8456; // Jakarta longitude

      // Call remote API
      final events = await remoteDataSource.getNearbyEvents(
        latitude: lat,
        longitude: lng,
        radiusKm: radiusKm,
        limit: limit,
        offset: offset,
      );

      // Create meta from response
      final meta = PaginationMeta(
        total: events.length,
        limit: limit,
        offset: offset,
        hasNext: events.length >= limit,
        hasPrevious: offset > 0,
      );

      return Right(PaginatedResponse(data: events, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get nearby events: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getStartingSoonEvents({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final events = await localDataSource.getEvents();
      final startingSoonEvents = events
          .where((event) => event.isStartingSoon)
          .take(limit)
          .toList();

      // TODO: Use real backend endpoint with pagination
      // For now, create empty meta
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: startingSoonEvents, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Failed to get starting soon events: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> getEventById(String id) async {
    try {
      // Fetch from remote only - no fallback
      final event = await remoteDataSource.getEventById(id);
      // Cache the event locally
      await localDataSource.cacheEvent(event);
      return Right(event);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get event by id: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> createEvent(Event event) async {
    try {
      final eventModel = EventModel.fromEntity(event);
      final eventData = eventModel.toJson();
      // Create on remote
      final createdEvent = await remoteDataSource.createEvent(eventData);
      // Cache locally
      await localDataSource.cacheEvent(createdEvent);
      return Right(createdEvent);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to create event: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> updateEvent(Event event) async {
    try {
      final eventModel = EventModel.fromEntity(event);
      final eventData = eventModel.toJson();
      // Update on remote
      final updatedEvent = await remoteDataSource.updateEvent(
        event.id,
        eventData,
      );
      // Cache locally
      await localDataSource.cacheEvent(updatedEvent);
      return Right(updatedEvent);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to update event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String id) async {
    try {
      // Delete on remote
      await remoteDataSource.deleteEvent(id);
      // Delete from cache
      await localDataSource.deleteEvent(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to delete event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinEvent(String eventId, String userId) async {
    try {
      // Join event on remote
      await remoteDataSource.joinEvent(eventId);
      // Update cache
      final event = await localDataSource.getEventById(eventId);
      if (event != null) {
        final updatedEvent = EventModel(
          id: event.id,
          title: event.title,
          description: event.description,
          category: event.category,
          startTime: event.startTime,
          endTime: event.endTime,
          location: event.location,
          host: event.host,
          imageUrls: event.imageUrls,
          maxAttendees: event.maxAttendees,
          attendeeIds: [...event.attendeeIds, userId],
          price: event.price,
          isFree: event.isFree,
          status: event.status,
          requirements: event.requirements,
        );
        await localDataSource.cacheEvent(updatedEvent);
      }
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to join event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveEvent(
    String eventId,
    String userId,
  ) async {
    try {
      // Leave event on remote
      await remoteDataSource.leaveEvent(eventId);
      // Update cache
      final event = await localDataSource.getEventById(eventId);
      if (event != null) {
        final updatedAttendees = event.attendeeIds
            .where((id) => id != userId)
            .toList();
        final updatedEvent = EventModel(
          id: event.id,
          title: event.title,
          description: event.description,
          category: event.category,
          startTime: event.startTime,
          endTime: event.endTime,
          location: event.location,
          host: event.host,
          imageUrls: event.imageUrls,
          maxAttendees: event.maxAttendees,
          attendeeIds: updatedAttendees,
          price: event.price,
          isFree: event.isFree,
          status: event.status,
          requirements: event.requirements,
        );
        await localDataSource.cacheEvent(updatedEvent);
      }
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to leave event: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> toggleEventInterest(
    String eventId,
    String userId,
  ) async {
    try {
      logger.d(
        '[EventRepository] Toggling interest for event: $eventId, user: $userId',
      );

      // Get current event from local cache ONLY (don't fetch from remote to avoid stale data)
      EventModel? cachedEvent = await localDataSource.getEventById(eventId);
      if (cachedEvent == null) {
        // If not in cache, we need full event data for constructing response
        // But fetch it AFTER the toggle to avoid stale data issue
        logger.d(
          '[EventRepository] Event not in cache, will fetch after toggle',
        );
      }

      // Toggle interest on remote FIRST (this gives us the authoritative count)
      final interestData = await remoteDataSource.toggleInterest(eventId);
      logger.d('[EventRepository] Toggle interest API response: $interestData');

      // Use toggle API response as source of truth for count.
      // Some responses may miss/garble `is_interested`, so we fallback to
      // deterministic local toggle state to keep UI (pin color/emoji) in sync.
      final newInterestCount = interestData?['interest_count'] as int?;
      final hadInterestedBefore =
          cachedEvent?.interestedUserIds.contains(userId) ?? false;
      final dynamic rawIsInterested = interestData?['is_interested'];
      final isInterested = rawIsInterested is bool
          ? rawIsInterested
          : !hadInterestedBefore;

      if (newInterestCount == null) {
        return Left(ServerFailure('Invalid interest count from API'));
      }

      logger.d(
        '[EventRepository] New count from API: $newInterestCount, is_interested: $isInterested',
      );

      // If we don't have cached event, fetch it now (after toggle, so we have fresh data)
      if (cachedEvent == null) {
        try {
          cachedEvent = await remoteDataSource.getEventById(eventId);
          await localDataSource.cacheEvent(cachedEvent);
          logger.d(
            '[EventRepository] Fetched and cached event from remote after toggle',
          );
        } catch (e) {
          logger.e('[EventRepository] Failed to fetch event from remote: $e');
          // Create minimal event if fetch fails
          // Import required entities
          final location = EventLocation(
            name: 'Unknown Location',
            address: 'Unknown Address',
            latitude: 0.0,
            longitude: 0.0,
          );
          final host = EventHost(
            id: '00000000-0000-0000-0000-000000000000',
            name: 'Unknown Host',
            avatar: '',
            bio: '',
          );

          cachedEvent = EventModel(
            id: eventId,
            title: '',
            description: '',
            category: EventCategory.meetup,
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            location: location,
            host: host,
            maxAttendees: 0,
          );
        }
      }

      final event = cachedEvent;

      // Construct fake interestedUserIds based on count from toggle API
      // (Backend doesn't return real IDs, so we generate fake ones for count consistency)
      final newInterestedUserIds = <String>[];
      for (int i = 0; i < newInterestCount; i++) {
        newInterestedUserIds.add('interested_$i');
      }

      // Add/remove real user ID based on is_interested
      if (isInterested) {
        if (!newInterestedUserIds.contains(userId)) {
          // Replace one fake ID with real user ID
          if (newInterestedUserIds.isNotEmpty) {
            newInterestedUserIds[0] = userId;
          } else {
            newInterestedUserIds.add(userId);
          }
          logger.d(
            '[EventRepository] Added real user ID $userId to interestedUserIds',
          );
        }
      } else {
        // Keep only fake IDs, remove real user ID if present
        newInterestedUserIds.remove(userId);
        logger.d(
          '[EventRepository] Removed real user ID $userId from interestedUserIds',
        );
      }

      // Construct updated event
      final updatedEvent = EventModel(
        id: event.id,
        title: event.title,
        description: event.description,
        category: event.category,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
        host: event.host,
        imageUrls: event.imageUrls,
        maxAttendees: event.maxAttendees,
        attendeeIds: event.attendeeIds,
        price: event.price,
        isFree: event.isFree,
        status: event.status,
        // V2: Private Events - TODO: Re-enable for V2
        // privacy: event.privacy,
        // pendingRequests: event.pendingRequests,
        requirements: event.requirements,
        interestedUserIds: newInterestedUserIds,
      );
      logger.d(
        '[EventRepository] Final interestedUserIds: ${updatedEvent.interestedUserIds.length} IDs (includes fake IDs + real user ID if interested)',
      );

      // Cache the updated event
      await localDataSource.cacheEvent(updatedEvent);

      // Return the updated event - EventModel IS already an Event (extends Event)
      return Right(updatedEvent);
    } catch (e) {
      logger.e('[EventRepository] Toggle interest error: $e');
      return Left(
        ServerFailure('Failed to toggle event interest: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getMyEvents({String? status}) async {
    try {
      // Fetch user's hosted events from remote
      final events = await remoteDataSource.getMyHostedEvents();

      // Filter by status if provided
      final filteredEvents = status != null
          ? events.where((event) {
              final eventStatus = event.status.toString().split('.').last;
              return eventStatus == status;
            }).toList()
          : events;

      return Right(filteredEvents);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get my events: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EventAttendee>>> getEventAttendees({
    required String eventId,
    String? status,
    String? search,
  }) async {
    try {
      final attendeesData = await remoteDataSource.getEventAttendees(
        eventId,
        status: status,
        search: search,
      );

      // Convert JSON data to EventAttendee entities
      final attendees = attendeesData.map((data) {
        return EventAttendee(
          id: data['id'] as String,
          name: data['name'] as String,
          avatar: data['avatar'] as String?,
          ticketType: data['ticket_type'] as String,
          ticketId: data['ticket_id'] as String,
          checkedIn: data['checked_in'] as bool? ?? false,
          checkedInAt: data['checked_in_at'] != null
              ? DateTime.parse(data['checked_in_at'] as String)
              : null,
          purchasedAt: DateTime.parse(data['purchased_at'] as String),
        );
      }).toList();

      return Right(attendees);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get event attendees: $e'));
    }
  }

  @override
  Future<Either<Failure, EventAttendee>> checkInAttendee({
    required String eventId,
    required String userId,
    required String ticketId,
  }) async {
    try {
      final result = await remoteDataSource.checkInAttendee(
        eventId: eventId,
        userId: userId,
        ticketId: ticketId,
      );

      final attendee = EventAttendee(
        id: result['user_id'] as String,
        name: result['user_name'] as String? ?? 'Attendee',
        avatar: result['user_avatar'] as String?,
        ticketType: result['ticket_type'] as String? ?? 'General',
        ticketId: ticketId,
        checkedIn: true,
        checkedInAt: result['checked_in_at'] != null
            ? DateTime.parse(result['checked_in_at'] as String)
            : DateTime.now(),
        purchasedAt: DateTime.now(),
      );

      return Right(attendee);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to check in attendee: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(File file) async {
    try {
      final imageUrl = await remoteDataSource.uploadImage(file);
      return Right(imageUrl);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to upload image: $e'));
    }
  }
}
