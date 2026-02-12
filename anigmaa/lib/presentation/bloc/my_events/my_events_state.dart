import 'package:equatable/equatable.dart';
import '../../../domain/entities/event.dart';

abstract class MyEventsState extends Equatable {
  const MyEventsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any events are loaded
class MyEventsInitial extends MyEventsState {}

/// Loading state while fetching events
class MyEventsLoading extends MyEventsState {}

/// State containing the list of user's events
class MyEventsLoaded extends MyEventsState {
  final List<Event> events;
  final String? successMessage;
  final String? errorMessage;

  const MyEventsLoaded({
    required this.events,
    this.successMessage,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [events, successMessage, errorMessage];

  MyEventsLoaded copyWith({
    List<Event>? events,
    String? successMessage,
    String? errorMessage,
  }) {
    return MyEventsLoaded(
      events: events ?? this.events,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  MyEventsLoaded clearMessages() {
    return MyEventsLoaded(
      events: events,
      successMessage: null,
      errorMessage: null,
    );
  }
}

/// Error state when loading fails
class MyEventsError extends MyEventsState {
  final String message;

  const MyEventsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when an event is successfully deleted
class MyEventDeleted extends MyEventsState {
  final String eventId;

  const MyEventDeleted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}
