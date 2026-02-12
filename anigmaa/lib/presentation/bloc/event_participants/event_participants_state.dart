import 'package:equatable/equatable.dart';
import '../../../domain/entities/event_attendee.dart';

abstract class EventParticipantsState extends Equatable {
  const EventParticipantsState();

  @override
  List<Object?> get props => [];
}

class EventParticipantsInitial extends EventParticipantsState {}

class EventParticipantsLoading extends EventParticipantsState {}

class EventParticipantsLoaded extends EventParticipantsState {
  final List<EventAttendee> attendees;
  final int checkedInCount;
  final String? currentFilter;
  final String? currentSearch;

  const EventParticipantsLoaded({
    required this.attendees,
    required this.checkedInCount,
    this.currentFilter,
    this.currentSearch,
  });

  EventParticipantsLoaded copyWith({
    List<EventAttendee>? attendees,
    int? checkedInCount,
    String? currentFilter,
    String? currentSearch,
    String? successMessage,
    String? errorMessage,
  }) {
    return EventParticipantsLoaded(
      attendees: attendees ?? this.attendees,
      checkedInCount: checkedInCount ?? this.checkedInCount,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSearch: currentSearch ?? this.currentSearch,
    );
  }

  @override
  List<Object?> get props => [attendees, checkedInCount, currentFilter, currentSearch];
}

class EventAttendeeCheckedIn extends EventParticipantsState {
  final EventAttendee attendee;
  final List<EventAttendee> attendees;
  final int checkedInCount;

  const EventAttendeeCheckedIn({
    required this.attendee,
    required this.attendees,
    required this.checkedInCount,
  });

  @override
  List<Object> get props => [attendee, attendees, checkedInCount];
}

class EventParticipantsError extends EventParticipantsState {
  final String message;

  const EventParticipantsError(this.message);

  @override
  List<Object> get props => [message];
}
