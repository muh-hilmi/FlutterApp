import 'package:equatable/equatable.dart';

abstract class EventParticipantsEvent extends Equatable {
  const EventParticipantsEvent();

  @override
  List<Object?> get props => [];
}

/// Load attendees for an event
class LoadEventAttendees extends EventParticipantsEvent {
  final String eventId;
  final String? status;
  final String? search;

  const LoadEventAttendees({required this.eventId, this.status, this.search});

  @override
  List<Object?> get props => [eventId, status, search];
}

/// Refresh attendees list
class RefreshEventAttendees extends EventParticipantsEvent {
  final String eventId;
  final String? status;
  final String? search;

  const RefreshEventAttendees({
    required this.eventId,
    this.status,
    this.search,
  });

  @override
  List<Object?> get props => [eventId, status, search];
}

/// Search attendees by name
class SearchAttendees extends EventParticipantsEvent {
  final String query;

  const SearchAttendees(this.query);

  @override
  List<Object?> get props => [query];
}

/// Check in an attendee
class CheckInAttendee extends EventParticipantsEvent {
  final String eventId;
  final String userId;
  final String ticketId;

  const CheckInAttendee({
    required this.eventId,
    required this.userId,
    required this.ticketId,
  });

  @override
  List<Object> get props => [eventId, userId, ticketId];
}

/// Filter attendees by status
class FilterAttendees extends EventParticipantsEvent {
  final String? status;

  const FilterAttendees(this.status);

  @override
  List<Object?> get props => [status];
}
