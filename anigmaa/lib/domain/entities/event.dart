import 'event_category.dart';
import 'event_host.dart';
import 'event_location.dart';
import '../../../injection_container.dart' as di;
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_config.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? createdAt; // Event creation timestamp
  final EventLocation location;
  final EventHost host;

  // Convenience getter for startTime to match usage in presentation layer
  DateTime get date => startTime;
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  final List<String> imageUrls;
  final int maxAttendees;
  final List<String> attendeeIds;
  final double? price;
  final bool isFree;
  final EventStatus status;
  final String? requirements;

  // Community fields
  final String? communityId; // ID of community if event created by community
  final bool isCommunityEvent; // True if event is from a community
  final bool communityMemberOnly; // True if only community members can join

  // Ticketing fields
  final bool ticketingEnabled; // Enable/disable ticket sales
  final int ticketsSold;
  final List<String> waitlistIds; // Waitlist when event is full

  // Interest fields
  final List<String>
  interestedUserIds; // Users who are interested in this event

  // User-specific state from backend (populated via is_user_attending)
  final bool isUserAttending; // True if the current user has an active ticket

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.createdAt,
    required this.location,
    required this.host,
    this.imageUrls = const [],
    required this.maxAttendees,
    this.attendeeIds = const [],
    this.price,
    this.isFree = true,
    this.status = EventStatus.upcoming,
    this.requirements,
    this.communityId,
    this.isCommunityEvent = false,
    this.communityMemberOnly = false,
    this.ticketingEnabled = false,
    this.ticketsSold = 0,
    this.waitlistIds = const [],
    this.interestedUserIds = const [],
    this.isUserAttending = false,
  });

  // Business logic getters
  int get currentAttendees => attendeeIds.length;
  int get spotsLeft => maxAttendees - currentAttendees;
  bool get isFull => currentAttendees >= maxAttendees;
  // IMPORTANT: Use UTC for time comparisons since backend sends UTC times
  bool get isStartingSoon => startTime.difference(DateTime.now().toUtc()).inHours < 2;

  /// Check if event is still active (not ended)
  bool get isActive => !hasEnded && status != EventStatus.cancelled;

  /// Check if event is completed (ended by time or status)
  bool get isCompleted => hasEnded;
  // IMPORTANT: Use UTC for time comparisons since backend sends UTC times
  bool get hasEnded =>
      DateTime.now().toUtc().isAfter(endTime) || status == EventStatus.ended;

  // Ticketing getters
  bool get hasTicketsAvailable => ticketingEnabled && !isSoldOut;
  bool get isSoldOut => ticketingEnabled && ticketsSold >= maxAttendees;
  int get ticketsRemaining => maxAttendees - ticketsSold;
  bool get hasWaitlist => waitlistIds.isNotEmpty;
  int get waitlistCount => waitlistIds.length;

  // Interest getters
  int get interestedCount => interestedUserIds.length;
  bool get hasInterestedUsers => interestedUserIds.isNotEmpty;
  bool get isInterested {
    try {
      final authService = di.sl<AuthService>();
      final currentUserId = authService.userId;
      return currentUserId != null && interestedUserIds.contains(currentUserId);
    } catch (e) {
      return false;
    }
  }

  // Attendance getters - Check if current user has joined/attended this event
  int get attendeeCount => attendeeIds.length;
  bool get hasJoined {
    // Prefer backend-provided flag (is_user_attending) over client-side check
    if (isUserAttending) return true;
    try {
      final authService = di.sl<AuthService>();
      final currentUserId = authService.userId;
      return currentUserId != null && attendeeIds.contains(currentUserId);
    } catch (e) {
      return false;
    }
  }

  // True if the current user is the host of this event
  bool get isUserHost {
    try {
      final authService = di.sl<AuthService>();
      final currentUserId = authService.userId;
      return currentUserId != null && host.id == currentUserId;
    } catch (e) {
      return false;
    }
  }

  bool get canJoin => !hasEnded && !isFull && !hasJoined && !isUserHost && status != EventStatus.cancelled;

  // Image URL helpers
  /// Get full image URLs with base URL prepended
  List<String> get fullImageUrls => imageUrls.map((url) {
    // If URL already starts with http/https, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Otherwise, prepend base URL WITHOUT /api/v1 path (images served from root)
    return '${AppConfig.baseUrl}$url';
  }).toList();

  /// Get first full image URL or null
  String? get fullImageUrl => fullImageUrls.isNotEmpty ? fullImageUrls.first : null;

  Event copyWith({
    String? id,
    String? title,
    String? description,
    EventCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    EventLocation? location,
    EventHost? host,
    List<String>? imageUrls,
    int? maxAttendees,
    List<String>? attendeeIds,
    double? price,
    bool? isFree,
    EventStatus? status,
    String? requirements,
    String? communityId,
    bool? isCommunityEvent,
    bool? communityMemberOnly,
    bool? ticketingEnabled,
    int? ticketsSold,
    List<String>? waitlistIds,
    List<String>? interestedUserIds,
    bool? isUserAttending,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      host: host ?? this.host,
      imageUrls: imageUrls ?? this.imageUrls,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      status: status ?? this.status,
      requirements: requirements ?? this.requirements,
      communityId: communityId ?? this.communityId,
      isCommunityEvent: isCommunityEvent ?? this.isCommunityEvent,
      communityMemberOnly: communityMemberOnly ?? this.communityMemberOnly,
      ticketingEnabled: ticketingEnabled ?? this.ticketingEnabled,
      ticketsSold: ticketsSold ?? this.ticketsSold,
      waitlistIds: waitlistIds ?? this.waitlistIds,
      interestedUserIds: interestedUserIds ?? this.interestedUserIds,
      isUserAttending: isUserAttending ?? this.isUserAttending,
    );
  }
}
