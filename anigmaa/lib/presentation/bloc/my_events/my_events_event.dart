import 'package:equatable/equatable.dart';

abstract class MyEventsEvent extends Equatable {
  const MyEventsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all events created by the current user
class LoadMyEvents extends MyEventsEvent {
  final String? status;

  const LoadMyEvents({this.status});

  @override
  List<Object?> get props => [status];
}

/// Event to refresh the list of user's events
class RefreshMyEvents extends MyEventsEvent {
  final String? status;

  const RefreshMyEvents({this.status});

  @override
  List<Object?> get props => [status];
}

/// Event to delete an event
class DeleteMyEvent extends MyEventsEvent {
  final String eventId;

  const DeleteMyEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Event to navigate to edit screen
class NavigateToEdit extends MyEventsEvent {
  final String eventId;

  const NavigateToEdit(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Event to navigate to check-in screen
class NavigateToCheckIn extends MyEventsEvent {
  final String eventId;

  const NavigateToCheckIn(this.eventId);

  @override
  List<Object?> get props => [eventId];
}
