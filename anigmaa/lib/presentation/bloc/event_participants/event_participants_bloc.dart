import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_event_attendees.dart';
import '../../../domain/usecases/check_in_attendee.dart' as check_in_usecase;
import '../../../domain/entities/event_attendee.dart';
import 'event_participants_event.dart';
import 'event_participants_state.dart';

/// BLoC for managing event participants and check-in
class EventParticipantsBloc extends Bloc<EventParticipantsEvent, EventParticipantsState> {
  final GetEventAttendees getEventAttendees;
  final check_in_usecase.CheckInAttendee checkInAttendeeUseCase;

  String? _currentEventId;
  String? _currentFilter;
  String? _currentSearch;

  EventParticipantsBloc({
    required this.getEventAttendees,
    required this.checkInAttendeeUseCase,
  }) : super(EventParticipantsInitial()) {
    on<LoadEventAttendees>(_onLoadEventAttendees);
    on<RefreshEventAttendees>(_onRefreshEventAttendees);
    on<SearchAttendees>(_onSearchAttendees);
    on<CheckInAttendee>(_onCheckInAttendee);
    on<FilterAttendees>(_onFilterAttendees);
  }

  Future<void> _onLoadEventAttendees(
    LoadEventAttendees event,
    Emitter<EventParticipantsState> emit,
  ) async {
    _currentEventId = event.eventId;
    _currentFilter = event.status;
    _currentSearch = event.search;

    emit(EventParticipantsLoading());

    final result = await getEventAttendees(
      GetEventAttendeesParams(
        eventId: event.eventId,
        status: event.status,
        search: event.search,
      ),
    );

    result.fold(
      (failure) => emit(EventParticipantsError(failure.message)),
      (attendees) {
        final checkedInCount = attendees.where((a) => a.checkedIn).length;
        emit(EventParticipantsLoaded(
          attendees: attendees,
          checkedInCount: checkedInCount,
          currentFilter: event.status,
          currentSearch: event.search,
        ));
      },
    );
  }

  Future<void> _onRefreshEventAttendees(
    RefreshEventAttendees event,
    Emitter<EventParticipantsState> emit,
  ) async {
    _currentEventId = event.eventId;
    _currentFilter = event.status;
    _currentSearch = event.search;

    // Keep current data while refreshing
    final currentState = state;
    if (currentState is! EventParticipantsLoaded) {
      emit(EventParticipantsLoading());
    }

    final result = await getEventAttendees(
      GetEventAttendeesParams(
        eventId: event.eventId,
        status: event.status,
        search: event.search,
      ),
    );

    result.fold(
      (failure) {
        if (currentState is EventParticipantsLoaded) {
          emit(currentState.copyWith(errorMessage: failure.message));
        } else {
          emit(EventParticipantsError(failure.message));
        }
      },
      (attendees) {
        final checkedInCount = attendees.where((a) => a.checkedIn).length;
        emit(EventParticipantsLoaded(
          attendees: attendees,
          checkedInCount: checkedInCount,
          currentFilter: event.status,
          currentSearch: event.search,
        ));
      },
    );
  }

  Future<void> _onSearchAttendees(
    SearchAttendees event,
    Emitter<EventParticipantsState> emit,
  ) async {
    if (_currentEventId == null) return;

    // Trigger load with search query
    add(LoadEventAttendees(
      eventId: _currentEventId!,
      status: _currentFilter,
      search: event.query.isEmpty ? null : event.query,
    ));
  }

  Future<void> _onCheckInAttendee(
    CheckInAttendee event,
    Emitter<EventParticipantsState> emit,
  ) async {
    // Only allow check-in if we have loaded state
    if (state is! EventParticipantsLoaded) return;

    final currentState = state as EventParticipantsLoaded;

    final result = await checkInAttendeeUseCase(
      check_in_usecase.CheckInAttendeeParams(
        eventId: event.eventId,
        userId: event.userId,
        ticketId: event.ticketId,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(errorMessage: failure.message));
      },
      (updatedAttendee) {
        // Update the attendees list with the checked-in attendee
        final List<EventAttendee> updatedAttendees = currentState.attendees.map((attendee) {
          return attendee.id == updatedAttendee.id ? updatedAttendee : attendee;
        }).toList();

        final newCheckedInCount = updatedAttendees.where((a) => a.checkedIn).length;

        emit(EventAttendeeCheckedIn(
          attendee: updatedAttendee,
          attendees: updatedAttendees,
          checkedInCount: newCheckedInCount,
        ));

        // Transition back to loaded state
        emit(EventParticipantsLoaded(
          attendees: updatedAttendees,
          checkedInCount: newCheckedInCount,
          currentFilter: currentState.currentFilter,
          currentSearch: currentState.currentSearch,
        ));
      },
    );
  }

  Future<void> _onFilterAttendees(
    FilterAttendees event,
    Emitter<EventParticipantsState> emit,
  ) async {
    if (_currentEventId == null) return;

    // Trigger load with filter
    add(LoadEventAttendees(
      eventId: _currentEventId!,
      status: event.status,
      search: _currentSearch,
    ));
  }
}
