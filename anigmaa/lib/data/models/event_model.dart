import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_host.dart';
import '../../domain/entities/event_location.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.startTime,
    required super.endTime,
    super.createdAt,
    required super.location,
    required super.host,
    super.imageUrls = const [],
    required super.maxAttendees,
    super.attendeeIds = const [],
    super.price,
    super.isFree = true,
    super.status = EventStatus.upcoming,
    super.requirements,
    super.interestedUserIds = const [],
    super.isUserAttending = false,
    super.ticketingEnabled = false,
    super.ticketsSold = 0,
    super.allowCancellation = true,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Backend uses snake_case consistently
    final startTime = json['start_time'];
    final endTime = json['end_time'];

    final createdAt = json['created_at'];
    final imageUrls = json['image_urls'];
    final maxAttendees = json['max_attendees'];

    // Handle attendee_ids or attendees_count from backend
    final attendeeIds = json['attendee_ids'];
    // Check both 'attendees_count' and 'event_attendees_count' (from posts feed)
    final attendeesCount = json['attendees_count'] ?? json['event_attendees_count'];

    final isFree = json['is_free'];
    // final isFree = json['is_free']; // Removed duplicate
    // pendingRequests from backend (not used in current implementation)
    // final pendingRequests = json['pending_requests'];

    // Handle interested_user_ids or interested_count from backend
    final interestedUserIds = json['interested_user_ids'];
    final interestedCount =
        json['interested_count'] ??
        json['interests_count'] ??
        json['pin_count'] ??
        json['likes_count'];

    // Parse location - expect nested object (backend standard)
    // Fallback to flat fields for backward compatibility (should be removed once backend is standardized)
    EventLocationModel location;
    if (json['location'] != null && json['location'] is Map) {
      location = EventLocationModel.fromJson(json['location']);
    } else {
      // Temporary fallback for legacy flat fields - backend should use nested Location object
      location = EventLocationModel(
        name: json['location_name'] as String? ?? '',
        address: json['location_address'] as String? ?? '',
        latitude: json['location_lat']?.toDouble() ?? 0.0,
        longitude: json['location_lng']?.toDouble() ?? 0.0,
        venue: json['venue'] as String?,
      );
    }

    // Parse host - expect nested object (backend standard)
    // Fallback to flat fields for backward compatibility (should be removed once backend is standardized)
    EventHostModel host;
    if (json['host'] != null && json['host'] is Map) {
      host = EventHostModel.fromJson(json['host']);
    } else {
      // Temporary fallback for legacy flat fields - backend should use nested Host object
      host = EventHostModel(
        id: json['host_id'] as String? ?? '',
        name: json['host_name'] as String? ?? 'Unknown',
        avatar: json['host_avatar_url'] as String? ?? '',
        bio: json['host_bio'] as String? ?? '',
        isVerified: json['host_is_verified'] as bool? ?? false,
        rating: json['host_rating']?.toDouble() ?? 0.0,
        eventsHosted: json['host_events_hosted'] as int? ?? 0,
      );
    }

    // Parse times
    final parsedStartTime = _parseDateTime(startTime) ?? DateTime.now();
    final parsedEndTime =
        _parseDateTime(endTime) ?? DateTime.now().add(const Duration(hours: 2));

    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Event',
      description: json['description'] as String? ?? '',
      category: EventCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => EventCategory.meetup,
      ),
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      createdAt: createdAt != null ? _parseDateTime(createdAt) : null,
      location: location,
      host: host,
      imageUrls: imageUrls != null
          ? List<String>.from(imageUrls is List ? imageUrls : [])
          : [],
      maxAttendees: maxAttendees is int
          ? maxAttendees
          : (maxAttendees is String ? int.tryParse(maxAttendees) ?? 50 : 50),
      // Generate dummy attendee IDs based on count if available
      attendeeIds: attendeeIds != null
          ? List<String>.from(attendeeIds is List ? attendeeIds : [])
          : (attendeesCount != null
                ? List<String>.generate(
                    attendeesCount is int
                        ? attendeesCount
                        : (attendeesCount is String
                              ? int.tryParse(attendeesCount) ?? 0
                              : 0),
                    (i) => 'attendee_$i',
                  )
                : <String>[]),
      price: json['price']?.toDouble(),
      isFree: isFree is bool
          ? isFree
          : (isFree == 1 || isFree == '1' || isFree == true),
      status: _parseEventStatus(json['status'] as String?),
      requirements: json['requirements'] as String?,
      // Generate dummy interested IDs based on count if available
      interestedUserIds: interestedUserIds != null
          ? List<String>.from(interestedUserIds)
          : (interestedCount != null
                ? List<String>.generate(
                    interestedCount is int
                        ? interestedCount
                        : (interestedCount as num).toInt(),
                    (i) => 'interested_$i',
                  )
                : <String>[]),
      isUserAttending: json['is_user_attending'] as bool? ?? false,
      ticketingEnabled: json['ticketing_enabled'] as bool? ?? false,
      ticketsSold: json['tickets_sold'] as int? ?? 0,
      allowCancellation: json['allow_cancellation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final startTimeUtc = startTime.toUtc();
    final endTimeUtc = endTime.toUtc();

    return {
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'start_time': startTimeUtc.toIso8601String(),
      'end_time': endTimeUtc.toIso8601String(),
      'location_name': location.name,
      'location_address': location.address,
      'location_lat': location.latitude,
      'location_lng': location.longitude,
      'max_attendees': maxAttendees,
      'price': price,
      'is_free': isFree,
      'requirements': requirements,
      'ticketing_enabled': false,
      'image_urls': imageUrls,
      'privacy': 'public',
    };
  }

  factory EventModel.fromEntity(Event event) {
    return EventModel(
      id: event.id,
      title: event.title,
      description: event.description,
      category: event.category,
      startTime: event.startTime,
      endTime: event.endTime,
      createdAt: event.createdAt,
      location: EventLocationModel.fromEntity(event.location),
      host: EventHostModel.fromEntity(event.host),
      imageUrls: event.imageUrls,
      maxAttendees: event.maxAttendees,
      attendeeIds: event.attendeeIds,
      price: event.price,
      isFree: event.isFree,
      status: event.status,
      requirements: event.requirements,
      interestedUserIds: event.interestedUserIds,
      isUserAttending: event.isUserAttending,
      ticketingEnabled: event.ticketingEnabled,
      ticketsSold: event.ticketsSold,
      allowCancellation: event.allowCancellation,
    );
  }

  /// Convert EventModel to Event entity
  /// Since EventModel extends Event, this just returns itself
  Event toEntity() => this;

  /// Parse event status from backend string
  static EventStatus _parseEventStatus(String? status) {
    if (status == null) return EventStatus.upcoming;

    final statusLower = status.toLowerCase();
    return EventStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == statusLower,
      orElse: () => EventStatus.upcoming,
    );
  }

  /// Safely parse DateTime from various types (String, int, DateTime, etc.)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Silently fail on parse errors - DateTime parsing issues should be handled at call site
        return null;
      }
    }

    if (value is int) {
      try {
        // Assume Unix timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        // Silently fail on parse errors
        return null;
      }
    }

    if (value is double) {
      try {
        // Assume Unix timestamp in milliseconds (as double)
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      } catch (e) {
        // Silently fail on parse errors
        return null;
      }
    }

    // Silently fail on unknown types
    return null;
  }
}

class EventHostModel extends EventHost {
  const EventHostModel({
    required super.id,
    required super.name,
    required super.avatar,
    required super.bio,
    super.isVerified = false,
    super.rating = 0.0,
    super.eventsHosted = 0,
  });

  factory EventHostModel.fromEntity(EventHost host) {
    return EventHostModel(
      id: host.id,
      name: host.name,
      avatar: host.avatar,
      bio: host.bio,
      isVerified: host.isVerified,
      rating: host.rating,
      eventsHosted: host.eventsHosted,
    );
  }

  factory EventHostModel.fromJson(Map<String, dynamic> json) {
    // Backend uses snake_case consistently
    // Support both 'avatar' and 'avatar_url' field names
    final avatarUrl = json['avatar_url'] ?? json['avatar'] ?? '';

    return EventHostModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: avatarUrl as String,
      bio: json['bio'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      rating: json['rating']?.toDouble() ?? 0.0,
      eventsHosted: json['events_hosted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'isVerified': isVerified,
      'rating': rating,
      'eventsHosted': eventsHosted,
    };
  }
}

class EventLocationModel extends EventLocation {
  const EventLocationModel({
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    super.venue,
  });

  factory EventLocationModel.fromEntity(EventLocation location) {
    return EventLocationModel(
      name: location.name,
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
      venue: location.venue,
    );
  }

  factory EventLocationModel.fromJson(Map<String, dynamic> json) {
    return EventLocationModel(
      name: json['name'] as String? ?? 'Unknown Location',
      address: json['address'] as String? ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      venue: json['venue'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'venue': venue,
    };
  }
}
