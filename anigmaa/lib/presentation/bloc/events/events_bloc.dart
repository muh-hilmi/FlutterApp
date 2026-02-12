import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../domain/entities/event.dart';
import '../../../domain/usecases/create_event.dart';
import '../../../domain/usecases/get_events.dart';
import '../../../domain/usecases/get_events_by_category.dart';
import '../../../domain/usecases/get_event_by_id.dart';
import '../../../domain/usecases/update_event.dart';
import '../../../domain/usecases/toggle_event_interest.dart';
import '../../../core/services/auth_service.dart';

import 'events_event.dart';
import 'events_state.dart';

import '../../../domain/usecases/get_nearby_events.dart';
import '../../../domain/usecases/upload_image.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final GetEvents getEvents;
  final GetEventsByCategory getEventsByCategory;
  final CreateEvent createEvent;
  final UpdateEvent updateEvent;
  final GetEventById getEventById;
  final ToggleEventInterest toggleEventInterest;
  final AuthService authService;
  final GetNearbyEvents getNearbyEvents;
  final UploadImage uploadImage;

  EventsBloc({
    required this.getEvents,
    required this.getEventsByCategory,
    required this.createEvent,
    required this.updateEvent,
    required this.getEventById,
    required this.toggleEventInterest,
    required this.authService,
    required this.getNearbyEvents,
    required this.uploadImage,
  }) : super(EventsInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<LoadEventsByMode>(_onLoadEventsByMode);
    on<LoadEventsByCategory>(_onLoadEventsByCategory);
    on<FilterEventsByCategory>(_onFilterEventsByCategory);
    on<CreateEventRequested>(_onCreateEvent);
    on<UpdateEventRequested>(_onUpdateEvent);
    on<RefreshEvents>(_onRefreshEvents);
    on<RemoveEvent>(_onRemoveEvent);
    on<ToggleInterestRequested>(
      _onToggleInterestRequested,
      transformer: sequential(),
    );
    on<LikeInterestRequested>(
      _onLikeInterestRequested,
      transformer: sequential(),
    );
    on<EnsureEventInState>(_onEnsureEventInState);
    on<LoadEventById>(_onLoadEventById);
    on<UploadEventImageRequested>(_onUploadEventImage);
  }

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoading());

    // Fetch feed and nearby events in parallel
    final results = await Future.wait([
      getEvents(const GetEventsParams(limit: 20, offset: 0)),
      getNearbyEvents(const GetNearbyEventsParams(limit: 10)),
    ]);

    final feedResult = results[0];
    final nearbyResult = results[1];

    feedResult.fold((failure) => emit(EventsError(failure.message)), (
      paginatedResponse,
    ) {
      final allEvents = paginatedResponse.data;
      // Filter out events that have already ended
      final now = DateTime.now().toUtc();

      final upcomingEvents = allEvents
          .where((event) => event.endTime.isAfter(now))
          .toList();

      // Process nearby events result
      List<Event> nearbyEvents = [];
      nearbyResult.fold(
        (failure) {
          print(
            '[EventsBloc] Failed to fetch nearby events: ${failure.message}',
          );
          // If real API fails, fallback to simple filtering as "Starting Soon"
          nearbyEvents = upcomingEvents
              .where((event) => event.isStartingSoon)
              .toList();
        },
        (response) {
          nearbyEvents = response.data
              .where((event) => event.endTime.isAfter(now))
              .toList();
        },
      );

      print(
        '[EventsBloc] Events loaded: ${upcomingEvents.length} feed, ${nearbyEvents.length} nearby',
      );

      emit(
        EventsLoaded(
          events: allEvents,
          filteredEvents: upcomingEvents,
          nearbyEvents: nearbyEvents,
          paginationMeta: paginatedResponse.meta,
        ),
      );
    });
  }

  Future<void> _onLoadEventsByMode(
    LoadEventsByMode event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoading());

    // Fetch feed and nearby events in parallel
    final results = await Future.wait([
      getEvents(GetEventsParams(limit: 50, offset: 0, mode: event.mode)),
      getNearbyEvents(const GetNearbyEventsParams(limit: 10)),
    ]);

    final feedResult = results[0];
    final nearbyResult = results[1];

    feedResult.fold((failure) => emit(EventsError(failure.message)), (
      paginatedResponse,
    ) {
      final allEvents = paginatedResponse.data;
      final now = DateTime.now().toUtc();

      final upcomingEvents = allEvents
          .where((event) => event.endTime.isAfter(now))
          .toList();

      // Process nearby events result
      List<Event> nearbyEvents = [];
      nearbyResult.fold(
        (failure) {
          nearbyEvents = upcomingEvents
              .where((event) => event.isStartingSoon)
              .toList();
        },
        (response) {
          nearbyEvents = response.data
              .where((event) => event.endTime.isAfter(now))
              .toList();
        },
      );

      emit(
        EventsLoaded(
          events: allEvents,
          filteredEvents: upcomingEvents,
          nearbyEvents: nearbyEvents,
          paginationMeta: paginatedResponse.meta,
        ),
      );
    });
  }

  Future<void> _onLoadEventsByCategory(
    LoadEventsByCategory event,
    Emitter<EventsState> emit,
  ) async {
    final result = await getEventsByCategory(
      GetEventsByCategoryParams(category: event.category, limit: 20, offset: 0),
    );

    result.fold((failure) => emit(EventsError(failure.message)), (
      paginatedResponse,
    ) {
      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;
        emit(
          currentState.copyWith(
            filteredEvents: paginatedResponse.data,
            selectedCategory: event.category,
            paginationMeta: paginatedResponse.meta,
          ),
        );
      }
    });
  }

  void _onFilterEventsByCategory(
    FilterEventsByCategory event,
    Emitter<EventsState> emit,
  ) {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;

      if (event.category == null) {
        // Clear filter - show all events
        emit(
          currentState.copyWith(
            filteredEvents: currentState.events,
            selectedCategory: null,
          ),
        );
      } else {
        // Apply category filter - show all events in category
        final filteredEvents = currentState.events
            .where((e) => e.category == event.category)
            .toList();

        emit(
          currentState.copyWith(
            filteredEvents: filteredEvents,
            selectedCategory: event.category,
          ),
        );
      }
    }
  }

  Future<void> _onCreateEvent(
    CreateEventRequested event,
    Emitter<EventsState> emit,
  ) async {
    // Set creating state
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      emit(currentState.copyWith(isCreatingEvent: true));
    }

    final result = await createEvent(CreateEventParams(event: event.event));

    result.fold(
      (failure) {
        // Set error message so UI can show snackbar
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          emit(
            currentState.copyWith(
              isCreatingEvent: false,
              createErrorMessage: 'Gagal bikin event: ${failure.message}',
            ),
          );
        } else {
          // If not loaded state, emit error
          emit(EventsError(failure.message));
        }
      },
      (createdEvent) {
        // Get current state and add the new event
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          // FIX: Check for duplicate by ID - replace if exists, otherwise add
          final updatedEvents = [
            createdEvent,
            ...currentState.events
                .where((e) => e.id != createdEvent.id)
                .toList(),
          ];
          // Use UTC for comparison since backend sends UTC times
          final isStartingSoon =
              createdEvent.startTime
                  .difference(DateTime.now().toUtc())
                  .inHours <=
              24;
          final updatedNearbyEvents = isStartingSoon
              ? [
                  createdEvent,
                  ...currentState.nearbyEvents
                      .where((e) => e.id != createdEvent.id)
                      .toList(),
                ]
              : currentState.nearbyEvents;

          // Apply category filter if selected
          final filteredEvents = currentState.selectedCategory == null
              ? updatedEvents
              : updatedEvents
                    .where((e) => e.category == currentState.selectedCategory)
                    .toList();

          emit(
            EventsLoaded(
              events: updatedEvents,
              filteredEvents: filteredEvents,
              nearbyEvents: updatedNearbyEvents,
              selectedCategory: currentState.selectedCategory,
              isCreatingEvent: false,
              successMessage: 'Event berhasil dibuat! 🎉',
            ),
          );
        } else {
          // If no current state, just reload
          add(LoadEvents());
        }
      },
    );
  }

  Future<void> _onUpdateEvent(
    UpdateEventRequested event,
    Emitter<EventsState> emit,
  ) async {
    final result = await updateEvent(UpdateEventParams(event: event.event));

    result.fold(
      (failure) {
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          emit(
            currentState.copyWith(
              createErrorMessage: 'Gagal update event: ${failure.message}',
            ),
          );
        } else {
          emit(EventsError(failure.message));
        }
      },
      (updatedEvent) {
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;

          // Update the event in the list
          final updatedEvents = currentState.events.map((e) {
            return e.id == updatedEvent.id ? updatedEvent : e;
          }).toList();

          final updatedFilteredEvents = currentState.filteredEvents.map((e) {
            return e.id == updatedEvent.id ? updatedEvent : e;
          }).toList();

          final updatedNearbyEvents = currentState.nearbyEvents.map((e) {
            return e.id == updatedEvent.id ? updatedEvent : e;
          }).toList();

          emit(
            currentState.copyWith(
              events: updatedEvents,
              filteredEvents: updatedFilteredEvents,
              nearbyEvents: updatedNearbyEvents,
              successMessage: 'Event berhasil diupdate! ✅',
            ),
          );
        } else {
          // If no current state, just emit the updated event
          emit(
            EventsLoaded(
              events: [updatedEvent],
              filteredEvents: [updatedEvent],
              nearbyEvents: updatedEvent.isStartingSoon ? [updatedEvent] : [],
            ),
          );
        }
      },
    );
  }

  Future<void> _onRefreshEvents(
    RefreshEvents event,
    Emitter<EventsState> emit,
  ) async {
    if (state is! EventsLoaded) {
      add(LoadEvents());
      return;
    }

    final currentState = state as EventsLoaded;
    final currentUserId = authService.userId;

    // PRESERVE local interest state during refresh
    // Key insight: We need to preserve whether the CURRENT USER was interested,
    // not just the dummy IDs from server
    final Map<String, bool> localUserInterestState = {};
    for (final e in currentState.events) {
      // Check if current user ID is actually in the list (not dummy IDs)
      if (currentUserId != null) {
        localUserInterestState[e.id] = e.interestedUserIds.contains(
          currentUserId,
        );
      }
    }

    // Fetch fresh data from server
    final result = await getEvents(const GetEventsParams(limit: 20, offset: 0));

    result.fold(
      (failure) {
        emit(EventsError(failure.message));
      },
      (paginatedResponse) {
        final serverEvents = paginatedResponse.data;

        // MERGE: Use server's interested_count but rebuild interestedUserIds
        // to include the current user if they were locally interested
        final mergedEvents = serverEvents.map((serverEvent) {
          final wasLocallyInterested =
              localUserInterestState[serverEvent.id] ?? false;
          final serverHasUserInterested =
              currentUserId != null &&
              serverEvent.interestedUserIds.contains(currentUserId);

          // If user was locally interested but server doesn't have their ID
          // (because server only returns count, not actual IDs), add them back
          if (wasLocallyInterested &&
              !serverHasUserInterested &&
              currentUserId != null) {
            final updatedUserIds = List<String>.from(
              serverEvent.interestedUserIds,
            );
            updatedUserIds.add(currentUserId);
            print(
              '[EventsBloc] Refresh - Preserving local interest for ${serverEvent.id}: user $currentUserId added back',
            );
            return serverEvent.copyWith(interestedUserIds: updatedUserIds);
          }

          return serverEvent;
        }).toList();

        // Filter out events that have already ended (for matchmaking context)
        // IMPORTANT: Convert to UTC for comparison because backend sends UTC times
        final now = DateTime.now().toUtc();
        print('[EventsBloc] _onRefreshEvents - Current time: $now (UTC)');
        print(
          '[EventsBloc] _onRefreshEvents - Total events from backend: ${mergedEvents.length}',
        );

        final upcomingEvents = mergedEvents.where((event) {
          final isUpcoming = event.endTime.isAfter(now);
          print(
            '[EventsBloc] _onRefreshEvents - Event "${event.title}": endTime=${event.endTime} (${event.endTime.isUtc ? "UTC" : "LOCAL"}), isUpcoming=$isUpcoming',
          );
          return isUpcoming;
        }).toList();

        print(
          '[EventsBloc] _onRefreshEvents - Upcoming events after filter: ${upcomingEvents.length}',
        );
        final nearbyEvents = upcomingEvents
            .where((event) => event.isStartingSoon)
            .toList();

        emit(
          EventsLoaded(
            events: mergedEvents,
            filteredEvents: upcomingEvents,
            nearbyEvents: nearbyEvents,
            paginationMeta: paginatedResponse.meta,
          ),
        );
      },
    );
  }

  void _onRemoveEvent(RemoveEvent event, Emitter<EventsState> emit) {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;

      // Remove event from all lists
      final updatedEvents = currentState.events
          .where((e) => e.id != event.eventId)
          .toList();
      final updatedFilteredEvents = currentState.filteredEvents
          .where((e) => e.id != event.eventId)
          .toList();
      final updatedNearbyEvents = currentState.nearbyEvents
          .where((e) => e.id != event.eventId)
          .toList();

      emit(
        EventsLoaded(
          events: updatedEvents,
          filteredEvents: updatedFilteredEvents,
          nearbyEvents: updatedNearbyEvents,
          selectedCategory: currentState.selectedCategory,
        ),
      );
    }
  }

  Future<void> _onToggleInterestRequested(
    ToggleInterestRequested event,
    Emitter<EventsState> emit,
  ) async {
    print(
      '[EventsBloc] _onToggleInterestRequested called! eventId=${event.event.id}',
    );
    print('[EventsBloc] Current state type: ${state.runtimeType}');

    // Get actual current user ID from AuthService
    final currentUserId = authService.userId;
    if (currentUserId == null) {
      print('[EventsBloc] User not logged in');
      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;
        emit(currentState.copyWith(createErrorMessage: 'User not logged in'));
      }
      return;
    }

    final eventId = event.event.id;

    // IDEMPOTENCY LOCK: Prevent re-entry while processing
    if (_processingToggleEventIds.contains(eventId)) {
      print('[EventsBloc] Toggle ALREADY IN PROGRESS for $eventId - ignoring');
      return;
    }
    _processingToggleEventIds.add(eventId);
    print('[EventsBloc] Toggle STARTED for $eventId');

    try {
      // Helper function to update event in list
      List<Event> updateEventInList(List<Event> events, Event updatedEvent) {
        return events.map((e) {
          if (e.id == updatedEvent.id) {
            return updatedEvent;
          }
          return e;
        }).toList();
      }

      // Find the event in state to get the latest local data (only if state is EventsLoaded)
      Event eventInState = event.event;
      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;
        try {
          eventInState = currentState.events.firstWhere((e) => e.id == eventId);
        } catch (_) {
          eventInState = event.event;
        }
      }

      // DETERMINISTIC STATE: Read CURRENT state, not what UI passed
      final currentInterests = List<String>.from(
        eventInState.interestedUserIds,
      );
      final wasInterested = currentInterests.contains(currentUserId);

      // INTENDED STATE: What we WANT after this operation completes
      final intendedIsInterested = !wasInterested;

      print(
        '[EventsBloc] ToggleInterest: eventId=$eventId, currentUserId=$currentUserId',
      );
      print(
        '[EventsBloc] Current state: isInterested=$wasInterested, count=${eventInState.interestedCount}',
      );
      print('[EventsBloc] Intended state: isInterested=$intendedIsInterested');

      // OPTIMISTIC UPDATE: Only emit if state is EventsLoaded
      // Keep track of whether we did an optimistic update for rollback
      bool didOptimisticUpdate = false;
      List<Event>? updatedEvents;
      List<Event>? updatedFilteredEvents;
      List<Event>? updatedNearbyEvents;

      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;

        // Apply intended state locally
        final optimisticInterests = List<String>.from(currentInterests);
        if (intendedIsInterested) {
          if (!optimisticInterests.contains(currentUserId)) {
            optimisticInterests.add(currentUserId);
          }
        } else {
          optimisticInterests.remove(currentUserId);
        }

        final optimisticallyUpdatedEvent = eventInState.copyWith(
          interestedUserIds: optimisticInterests,
        );

        // Emit optimistic update
        updatedEvents = updateEventInList(
          currentState.events,
          optimisticallyUpdatedEvent,
        );
        updatedFilteredEvents = updateEventInList(
          currentState.filteredEvents,
          optimisticallyUpdatedEvent,
        );
        updatedNearbyEvents = updateEventInList(
          currentState.nearbyEvents,
          optimisticallyUpdatedEvent,
        );
        didOptimisticUpdate = true;

        emit(
          currentState.copyWith(
            events: updatedEvents,
            filteredEvents: updatedFilteredEvents,
            nearbyEvents: updatedNearbyEvents,
          ),
        );
        print('[EventsBloc] Optimistic update emitted');
      } else {
        print(
          '[EventsBloc] State not EventsLoaded, skipping optimistic update',
        );
      }

      // Call API in background
      final result = await toggleEventInterest(eventId, currentUserId);

      result.fold(
        (failure) {
          print('[EventsBloc] API failed: ${failure.message}');

          // ROLLBACK: Only if we did an optimistic update
          if (didOptimisticUpdate && updatedEvents != null) {
            final revertedEvent = eventInState.copyWith(
              interestedUserIds: currentInterests,
            );

            final revertedEvents = updateEventInList(
              updatedEvents,
              revertedEvent,
            );
            final revertedFilteredEvents = updateEventInList(
              updatedFilteredEvents!,
              revertedEvent,
            );
            final revertedNearbyEvents = updateEventInList(
              updatedNearbyEvents!,
              revertedEvent,
            );

            final latestState = state;
            if (latestState is EventsLoaded) {
              emit(
                latestState.copyWith(
                  events: revertedEvents,
                  filteredEvents: revertedFilteredEvents,
                  nearbyEvents: revertedNearbyEvents,
                  createErrorMessage:
                      'Gagal update interest: ${failure.message}',
                ),
              );
            }
          }
        },
        (updatedEvent) {
          print(
            '[EventsBloc] API success! Updated event: ${updatedEvent.id}, interestedCount=${updatedEvent.interestedCount}',
          );

          final latestState = state;
          if (latestState is! EventsLoaded) {
            // If state is not EventsLoaded (e.g., EventsInitial), emit new EventsLoaded state
            print(
              '[EventsBloc] State not EventsLoaded, emitting new EventsLoaded with updated event',
            );
            emit(
              EventsLoaded(
                events: [updatedEvent],
                filteredEvents: [updatedEvent],
                nearbyEvents: [],
              ),
            );
            return;
          }

          // Update with server data
          final finalEvents = updateEventInList(
            latestState.events,
            updatedEvent,
          );
          final finalFilteredEvents = updateEventInList(
            latestState.filteredEvents,
            updatedEvent,
          );
          final finalNearbyEvents = updateEventInList(
            latestState.nearbyEvents,
            updatedEvent,
          );

          emit(
            latestState.copyWith(
              events: finalEvents,
              filteredEvents: finalFilteredEvents,
              nearbyEvents: finalNearbyEvents,
            ),
          );
          print(
            '[EventsBloc] State emitted: eventId=${updatedEvent.id}, count=${updatedEvent.interestedCount}',
          );

          // Update permanent lock based on new state
          if (updatedEvent.isInterested) {
            _likedEventIds.add(eventId);
            print(
              '[EventsBloc] Added $eventId to permanent liked lock (toggle)',
            );
          } else {
            _likedEventIds.remove(eventId);
            print(
              '[EventsBloc] Removed $eventId from permanent liked lock (unlike)',
            );
          }
        },
      );
    } finally {
      // ALWAYS release lock
      _processingToggleEventIds.remove(eventId);
      print('[EventsBloc] Toggle COMPLETED for $eventId');
    }
  }

  // LIKE-ONLY handler (TikTok/Instagram style)
  // Double-tap on card = Like only (idempotent, never unlikes)
  Future<void> _onLikeInterestRequested(
    LikeInterestRequested event,
    Emitter<EventsState> emit,
  ) async {
    print(
      '[EventsBloc] _onLikeInterestRequested called! eventId=${event.event.id}',
    );
    print('[EventsBloc] Current state type: ${state.runtimeType}');

    // Get actual current user ID from AuthService
    final currentUserId = authService.userId;
    if (currentUserId == null) {
      print('[EventsBloc] User not logged in');
      // Can only emit error if we have EventsLoaded state
      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;
        emit(
          currentState.copyWith(
            createErrorMessage: 'Harus login dulu untuk likes! 🔒',
          ),
        );
        emit(currentState.copyWith(createErrorMessage: null));
      }
      return;
    }

    final eventId = event.event.id;

    // PERMANENT LOCK: If already liked in this session, skip
    if (_likedEventIds.contains(eventId)) {
      print(
        '[EventsBloc] Like ALREADY LIKED in this session for $eventId - ignoring',
      );
      return;
    }

    // IDEMPOTENCY LOCK: Prevent re-entry while processing
    if (_processingToggleEventIds.contains(eventId)) {
      print('[EventsBloc] Like ALREADY IN PROGRESS for $eventId - ignoring');
      return;
    }

    // Find the event in state to get the latest local data (only if state is EventsLoaded)
    Event eventInState = event.event;
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      try {
        eventInState = currentState.events.firstWhere((e) => e.id == eventId);
      } catch (_) {
        eventInState = event.event;
      }
    }

    final currentInterests = List<String>.from(eventInState.interestedUserIds);
    final wasInterested = currentInterests.contains(currentUserId);

    // IDEMPOTENCY: If already interested, we typically do nothing.
    // However, to be safe and ensure UI sync, we only skip if we are 100% sure.
    if (wasInterested) {
      print('[EventsBloc] Like SKIPPED for $eventId - already interested');
      return;
    }

    // Acquire lock
    _processingToggleEventIds.add(eventId);
    print('[EventsBloc] Like STARTED for $eventId');

    try {
      // Helper function to update event in list
      List<Event> updateEventInList(List<Event> events, Event updatedEvent) {
        return events.map((e) {
          if (e.id == updatedEvent.id) {
            return updatedEvent;
          }
          return e;
        }).toList();
      }

      print(
        '[EventsBloc] LikeInterest: eventId=$eventId, currentUserId=$currentUserId',
      );
      print(
        '[EventsBloc] Current state: isInterested=false, count=${eventInState.interestedCount}',
      );

      // OPTIMISTIC UPDATE: Only emit if state is EventsLoaded
      // Keep track of whether we did an optimistic update for rollback
      bool didOptimisticUpdate = false;
      List<Event>? updatedEvents;
      List<Event>? updatedFilteredEvents;
      List<Event>? updatedNearbyEvents;

      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;

        // Add user to interested list
        final optimisticInterests = List<String>.from(currentInterests);
        if (!optimisticInterests.contains(currentUserId)) {
          optimisticInterests.add(currentUserId);
        }

        final optimisticallyUpdatedEvent = eventInState.copyWith(
          interestedUserIds: optimisticInterests,
        );

        // Emit optimistic update
        updatedEvents = updateEventInList(
          currentState.events,
          optimisticallyUpdatedEvent,
        );
        updatedFilteredEvents = updateEventInList(
          currentState.filteredEvents,
          optimisticallyUpdatedEvent,
        );
        updatedNearbyEvents = updateEventInList(
          currentState.nearbyEvents,
          optimisticallyUpdatedEvent,
        );
        didOptimisticUpdate = true;

        emit(
          currentState.copyWith(
            events: updatedEvents,
            filteredEvents: updatedFilteredEvents,
            nearbyEvents: updatedNearbyEvents,
          ),
        );
        print('[EventsBloc] Optimistic like update emitted');
      } else {
        print(
          '[EventsBloc] State not EventsLoaded, skipping optimistic update',
        );
      }

      // Call API in background
      final result = await toggleEventInterest(eventId, currentUserId);

      result.fold(
        (failure) {
          print('[EventsBloc] API failed: ${failure.message}');

          // ROLLBACK: Only if we did an optimistic update
          if (didOptimisticUpdate && updatedEvents != null) {
            final revertedEvent = eventInState.copyWith(
              interestedUserIds: currentInterests,
            );

            final revertedEvents = updateEventInList(
              updatedEvents,
              revertedEvent,
            );
            final revertedFilteredEvents = updateEventInList(
              updatedFilteredEvents!,
              revertedEvent,
            );
            final revertedNearbyEvents = updateEventInList(
              updatedNearbyEvents!,
              revertedEvent,
            );

            final latestState = state;
            if (latestState is EventsLoaded) {
              emit(
                latestState.copyWith(
                  events: revertedEvents,
                  filteredEvents: revertedFilteredEvents,
                  nearbyEvents: revertedNearbyEvents,
                  createErrorMessage:
                      'Gagal update interest: ${failure.message}',
                ),
              );
            }
          }
        },
        (updatedEvent) {
          print(
            '[EventsBloc] API success! Updated event: ${updatedEvent.id}, interestedCount=${updatedEvent.interestedCount}',
          );

          final latestState = state;
          if (latestState is! EventsLoaded) {
            // If state is not EventsLoaded (e.g., EventsInitial), emit new EventsLoaded state
            print(
              '[EventsBloc] State not EventsLoaded, emitting new EventsLoaded with updated event',
            );
            emit(
              EventsLoaded(
                events: [updatedEvent],
                filteredEvents: [updatedEvent],
                nearbyEvents: [],
              ),
            );
            return;
          }

          // Update with server data
          final finalEvents = updateEventInList(
            latestState.events,
            updatedEvent,
          );
          final finalFilteredEvents = updateEventInList(
            latestState.filteredEvents,
            updatedEvent,
          );
          final finalNearbyEvents = updateEventInList(
            latestState.nearbyEvents,
            updatedEvent,
          );

          emit(
            latestState.copyWith(
              events: finalEvents,
              filteredEvents: finalFilteredEvents,
              nearbyEvents: finalNearbyEvents,
            ),
          );
          print(
            '[EventsBloc] State emitted: eventId=${updatedEvent.id}, count=${updatedEvent.interestedCount}',
          );

          // PERMANENT LOCK: Add to liked set after successful like
          _likedEventIds.add(eventId);
          print('[EventsBloc] Added $eventId to permanent liked lock');
        },
      );
    } catch (e) {
      print('[EventsBloc] Like error: $e');
    } finally {
      // ALWAYS release lock
      _processingToggleEventIds.remove(eventId);
    }
  }

  Future<void> _onEnsureEventInState(
    EnsureEventInState event,
    Emitter<EventsState> emit,
  ) async {
    // If state is not loaded, just return (can't ensure without loaded state)
    if (state is! EventsLoaded) return;

    final currentState = state as EventsLoaded;

    // Check if event already exists in state
    final existingEvent = currentState.events.firstWhere(
      (e) => e.id == event.event.id,
      orElse: () => event.event,
    );

    // If the passed event has different data (e.g., updated interest count),
    // we need to update it in the state
    final needsUpdate =
        existingEvent.interestedCount != event.event.interestedCount ||
        existingEvent.isInterested != event.event.isInterested;

    if (!currentState.events.any((e) => e.id == event.event.id)) {
      // Event not in state - add it
      // FIX: Check for duplicate by ID - replace if exists, otherwise add
      final updatedEvents = [
        event.event,
        ...currentState.events.where((e) => e.id != event.event.id).toList(),
      ];
      final updatedFilteredEvents = currentState.selectedCategory == null
          ? updatedEvents
          : updatedEvents
                .where((e) => e.category == currentState.selectedCategory)
                .toList();

      // Use UTC for comparison since backend sends UTC times
      final isStartingSoon =
          event.event.startTime.difference(DateTime.now().toUtc()).inHours <=
          24;
      final updatedNearbyEvents = isStartingSoon
          ? [
              event.event,
              ...currentState.nearbyEvents
                  .where((e) => e.id != event.event.id)
                  .toList(),
            ]
          : currentState.nearbyEvents;

      emit(
        currentState.copyWith(
          events: updatedEvents,
          filteredEvents: updatedFilteredEvents,
          nearbyEvents: updatedNearbyEvents,
        ),
      );
    } else if (needsUpdate) {
      // Event exists but needs update (e.g., interest count changed)
      List<Event> updateEventInList(List<Event> events) {
        return events.map((e) {
          if (e.id == event.event.id) {
            return event.event;
          }
          return e;
        }).toList();
      }

      final updatedEvents = updateEventInList(currentState.events);
      final updatedFilteredEvents = updateEventInList(
        currentState.filteredEvents,
      );
      final updatedNearbyEvents = updateEventInList(currentState.nearbyEvents);

      emit(
        currentState.copyWith(
          events: updatedEvents,
          filteredEvents: updatedFilteredEvents,
          nearbyEvents: updatedNearbyEvents,
        ),
      );
    }
  }

  // IDMPOTENCY LOCK: Track events currently being toggled to prevent race conditions
  final Set<String> _processingToggleEventIds = {};
  final Set<String> _likedEventIds =
      {}; // Permanent lock for likes (can only like once per session)

  Future<void> _onLoadEventById(
    LoadEventById event,
    Emitter<EventsState> emit,
  ) async {
    final result = await getEventById(event.eventId);

    result.fold(
      (failure) {
        // If we're in EventsLoaded state, keep it and just add error message
        if (state is EventsLoaded) {
          emit(
            (state as EventsLoaded).copyWith(
              createErrorMessage: 'Failed to load event: ${failure.message}',
            ),
          );
        } else {
          emit(EventsError(failure.message));
        }
      },
      (loadedEvent) {
        // If state is EventsLoaded, update/add this event to the list
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;

          // Check if event already exists in local state
          final existingEventIndex = currentState.events.indexWhere(
            (e) => e.id == loadedEvent.id,
          );
          final existingEvent = existingEventIndex >= 0
              ? currentState.events[existingEventIndex]
              : null;

          // Get current user ID to check local interest state
          final currentUserId = authService.userId;

          // Preserve local interest state if user has toggled it recently
          // This prevents race condition where LoadEventById overwrites ToggleInterestRequested
          Event eventToUse = loadedEvent;
          if (currentUserId != null &&
              existingEvent != null &&
              existingEvent.id == loadedEvent.id) {
            final localIsInterested = existingEvent.interestedUserIds.contains(
              currentUserId,
            );
            final serverIsInterested = loadedEvent.interestedUserIds.contains(
              currentUserId,
            );

            // If local state differs from server state, preserve local state
            // This handles the case where user just toggled but server hasn't caught up
            if (localIsInterested != serverIsInterested) {
              print(
                '[EventsBloc] LoadEventById - Preserving local interest state for ${loadedEvent.id}: local=$localIsInterested, server=$serverIsInterested',
              );

              // Create a hybrid event with server data but local interest state
              final hybridUserIds = List<String>.from(
                loadedEvent.interestedUserIds,
              );
              if (localIsInterested && !serverIsInterested) {
                // Add user to server's interested list
                hybridUserIds.add(currentUserId);
              } else if (!localIsInterested && serverIsInterested) {
                // Remove user from server's interested list
                hybridUserIds.remove(currentUserId);
              }

              eventToUse = loadedEvent.copyWith(
                interestedUserIds: hybridUserIds,
              );
            }
          }

          // Check if event already exists
          final existingIndex = currentState.events.indexWhere(
            (e) => e.id == eventToUse.id,
          );

          final updatedEvents = List<Event>.from(currentState.events);
          if (existingIndex >= 0) {
            // Replace existing event
            updatedEvents[existingIndex] = eventToUse;
          } else {
            // Add new event at the beginning
            updatedEvents.insert(0, eventToUse);
          }

          // Update filtered events and nearby events similarly
          final updatedFilteredEvents = List<Event>.from(
            currentState.filteredEvents,
          );
          final filteredIndex = updatedFilteredEvents.indexWhere(
            (e) => e.id == eventToUse.id,
          );
          if (filteredIndex >= 0) {
            updatedFilteredEvents[filteredIndex] = eventToUse;
          } else if (currentState.selectedCategory == null ||
              eventToUse.category == currentState.selectedCategory) {
            updatedFilteredEvents.insert(0, eventToUse);
          }

          final updatedNearbyEvents = List<Event>.from(
            currentState.nearbyEvents,
          );
          final nearbyIndex = updatedNearbyEvents.indexWhere(
            (e) => e.id == eventToUse.id,
          );
          if (nearbyIndex >= 0) {
            updatedNearbyEvents[nearbyIndex] = eventToUse;
          }

          emit(
            currentState.copyWith(
              events: updatedEvents,
              filteredEvents: updatedFilteredEvents,
              nearbyEvents: updatedNearbyEvents,
            ),
          );
          print(
            '[EventsBloc] LoadEventById - Emitted EventsLoaded with ${updatedEvents.length} events. First event ID: ${updatedEvents.first.id}',
          );
        } else {
          // If state is not EventsLoaded, create a new EventsLoaded with just this event
          print(
            '[EventsBloc] LoadEventById - State is ${state.runtimeType}, creating new EventsLoaded with event ${loadedEvent.id}',
          );
          emit(
            EventsLoaded(
              events: [loadedEvent],
              filteredEvents: [loadedEvent],
              nearbyEvents: loadedEvent.isStartingSoon ? [loadedEvent] : [],
            ),
          );
          print(
            '[EventsBloc] LoadEventById - Emitted new EventsLoaded with 1 event. Event ID: ${loadedEvent.id}',
          );
        }

        print(
          '[EventsBloc] LoadEventById - Loaded event ${loadedEvent.id} with interestedCount: ${loadedEvent.interestedUserIds.length}',
        );
      },
    );
  }

  Future<void> _onUploadEventImage(
    UploadEventImageRequested event,
    Emitter<EventsState> emit,
  ) async {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      emit(currentState.copyWith(isCreatingEvent: true));

      final result = await uploadImage(event.file);

      result.fold(
        (failure) {
          emit(
            currentState.copyWith(
              isCreatingEvent: false,
              createErrorMessage: 'Upload gagal: ${failure.message}',
            ),
          );
        },
        (imageUrl) {
          emit(
            currentState.copyWith(
              isCreatingEvent: false,
              lastUploadedImageUrl: imageUrl,
              successMessage: 'Foto berhasil diupload! 📸',
            ),
          );
        },
      );
    }
  }
}
