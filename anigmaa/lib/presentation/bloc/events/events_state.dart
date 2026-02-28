import 'package:equatable/equatable.dart';
import '../../../core/models/pagination.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<Event> events;
  final List<Event> filteredEvents;
  final List<Event> nearbyEvents;
  final PaginationMeta? paginationMeta;
  final PaginationMeta? nearbyPaginationMeta;
  final EventCategory? selectedCategory;
  final bool isCreatingEvent;
  final String? createErrorMessage;
  final String? successMessage;
  final String? lastUploadedImageUrl;

  const EventsLoaded({
    required this.events,
    required this.filteredEvents,
    required this.nearbyEvents,
    this.paginationMeta,
    this.nearbyPaginationMeta,
    this.selectedCategory,
    this.isCreatingEvent = false,
    this.createErrorMessage,
    this.successMessage,
    this.lastUploadedImageUrl,
  });

  // Computed properties for pagination
  bool get hasMore => paginationMeta?.hasNext ?? false;
  int get currentOffset => paginationMeta?.nextOffset ?? events.length;

  @override
  List<Object?> get props => [
    events,
    filteredEvents,
    nearbyEvents,
    paginationMeta,
    nearbyPaginationMeta,
    selectedCategory,
    isCreatingEvent,
    createErrorMessage,
    successMessage,
    lastUploadedImageUrl,
  ];

  EventsLoaded copyWith({
    List<Event>? events,
    List<Event>? filteredEvents,
    List<Event>? nearbyEvents,
    PaginationMeta? paginationMeta,
    PaginationMeta? nearbyPaginationMeta,
    EventCategory? selectedCategory,
    bool? isCreatingEvent,
    String? createErrorMessage,
    String? successMessage,
    String? lastUploadedImageUrl,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      nearbyEvents: nearbyEvents ?? this.nearbyEvents,
      paginationMeta: paginationMeta ?? this.paginationMeta,
      nearbyPaginationMeta: nearbyPaginationMeta ?? this.nearbyPaginationMeta,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isCreatingEvent: isCreatingEvent ?? this.isCreatingEvent,
      createErrorMessage: createErrorMessage,
      successMessage: successMessage,
      lastUploadedImageUrl: lastUploadedImageUrl ?? this.lastUploadedImageUrl,
    );
  }

  EventsLoaded clearMessages() {
    return EventsLoaded(
      events: events,
      filteredEvents: filteredEvents,
      nearbyEvents: nearbyEvents,
      paginationMeta: paginationMeta,
      nearbyPaginationMeta: nearbyPaginationMeta,
      selectedCategory: selectedCategory,
      isCreatingEvent: isCreatingEvent,
      createErrorMessage: null,
      successMessage: null,
      lastUploadedImageUrl: null,
    );
  }
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Offline state - shows cached events when network is unavailable
class EventsOffline extends EventsState {
  final List<Event> cachedEvents;
  final String? message;

  const EventsOffline({
    required this.cachedEvents,
    this.message = 'Offline — menampilkan data terakhir',
  });

  @override
  List<Object?> get props => [cachedEvents, message];
}

class EventCreated extends EventsState {
  final Event event;

  const EventCreated(this.event);

  @override
  List<Object?> get props => [event];
}
