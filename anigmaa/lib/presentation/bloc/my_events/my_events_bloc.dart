import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/usecases/get_my_events.dart';
import '../../../domain/usecases/delete_event.dart';

import 'my_events_event.dart';
import 'my_events_state.dart';

/// BLoC for managing events created by the current user
/// Handles loading, deleting, and state management for user's hosted events
class MyEventsBloc extends Bloc<MyEventsEvent, MyEventsState> {
  final GetMyEvents getMyEvents;
  final DeleteEvent deleteEvent;

  MyEventsBloc({required this.getMyEvents, required this.deleteEvent})
    : super(MyEventsInitial()) {
    on<LoadMyEvents>(_onLoadMyEvents);
    on<RefreshMyEvents>(_onRefreshMyEvents);
    on<DeleteMyEvent>(_onDeleteMyEvent);
    on<NavigateToEdit>(_onNavigateToEdit);
    on<NavigateToCheckIn>(_onNavigateToCheckIn);
    on<ArchiveMyEvent>(_onArchiveMyEvent);
    on<UnarchiveMyEvent>(_onUnarchiveMyEvent);
  }

  /// Load all events created by the current user
  Future<void> _onLoadMyEvents(
    LoadMyEvents event,
    Emitter<MyEventsState> emit,
  ) async {
    emit(MyEventsLoading());

    final result = await getMyEvents(GetMyEventsParams(status: event.status));

    result.fold(
      (failure) => emit(MyEventsError(failure.message)),
      (events) => emit(MyEventsLoaded(events: events)),
    );
  }

  /// Refresh the list of events
  Future<void> _onRefreshMyEvents(
    RefreshMyEvents event,
    Emitter<MyEventsState> emit,
  ) async {
    // If current state is loaded, keep showing data while refreshing
    final currentState = state;
    if (currentState is! MyEventsLoaded) {
      emit(MyEventsLoading());
    }

    final result = await getMyEvents(GetMyEventsParams(status: event.status));

    result.fold(
      (failure) {
        // If we had previous data, keep it but show error
        if (currentState is MyEventsLoaded) {
          emit(currentState.copyWith(errorMessage: failure.message));
        } else {
          emit(MyEventsError(failure.message));
        }
      },
      (events) {
        emit(
          MyEventsLoaded(
            events: events,
            successMessage: 'Event berhasil di-refresh',
          ),
        );
      },
    );
  }

  /// Delete an event created by the user
  Future<void> _onDeleteMyEvent(
    DeleteMyEvent event,
    Emitter<MyEventsState> emit,
  ) async {
    // Only proceed if we have loaded state
    if (state is! MyEventsLoaded) return;

    final currentState = state as MyEventsLoaded;

    // Call delete use case
    final result = await deleteEvent(DeleteEventParams(eventId: event.eventId));

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            errorMessage: 'Gagal menghapus event: ${failure.message}',
          ),
        );
      },
      (_) {
        // Remove event from list - ensure we only remove ONE event by exact ID match
        final updatedEvents = <Event>[];
        bool foundAndRemoved = false;

        for (final e in currentState.events) {
          if (!foundAndRemoved && e.id == event.eventId) {
            // Skip this event (remove it)
            foundAndRemoved = true;
          } else {
            // Keep this event
            updatedEvents.add(e);
          }
        }

        emit(
          MyEventsLoaded(
            events: updatedEvents,
            successMessage: 'Event berhasil dihapus',
          ),
        );
      },
    );
  }

  /// Navigate to edit screen (handled by UI)
  void _onNavigateToEdit(NavigateToEdit event, Emitter<MyEventsState> emit) {
    // Navigation is handled by the UI layer
    // This event is just for consistency/tracking if needed
  }

  /// Navigate to check-in screen (handled by UI)
  void _onNavigateToCheckIn(
    NavigateToCheckIn event,
    Emitter<MyEventsState> emit,
  ) {
    // Navigation is handled by the UI layer
    // This event is just for consistency/tracking if needed
  }

  /// Archive an event
  void _onArchiveMyEvent(
    ArchiveMyEvent event,
    Emitter<MyEventsState> emit,
  ) {
    // Only proceed if we have loaded state
    if (state is! MyEventsLoaded) return;

    final currentState = state as MyEventsLoaded;

    // Update event's isArchived status
    final updatedEvents = currentState.events.map((e) {
      if (e.id == event.eventId) {
        return e.copyWith(isArchived: true);
      }
      return e;
    }).toList();

    emit(
      MyEventsLoaded(
        events: updatedEvents,
        successMessage: 'Event berhasil diarsipkan',
      ),
    );
  }

  /// Unarchive an event
  void _onUnarchiveMyEvent(
    UnarchiveMyEvent event,
    Emitter<MyEventsState> emit,
  ) {
    // Only proceed if we have loaded state
    if (state is! MyEventsLoaded) return;

    final currentState = state as MyEventsLoaded;

    // Update event's isArchived status
    final updatedEvents = currentState.events.map((e) {
      if (e.id == event.eventId) {
        return e.copyWith(isArchived: false);
      }
      return e;
    }).toList();

    emit(
      MyEventsLoaded(
        events: updatedEvents,
        successMessage: 'Arsip event berhasil dibatalkan',
      ),
    );
  }
}
