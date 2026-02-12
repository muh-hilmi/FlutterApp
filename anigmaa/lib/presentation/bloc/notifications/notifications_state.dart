part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, loaded, refreshing, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<domain.Notification> notifications;
  final String? errorMessage;
  final int unreadCount;
  final bool hasReachedMax;

  const NotificationsState({
    required this.status,
    this.notifications = const [],
    this.errorMessage,
    this.unreadCount = 0,
    this.hasReachedMax = false,
  });

  const NotificationsState.initial()
      : status = NotificationsStatus.initial,
        notifications = const [],
        errorMessage = null,
        unreadCount = 0,
        hasReachedMax = false;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<domain.Notification>? notifications,
    String? errorMessage,
    int? unreadCount,
    bool? hasReachedMax,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        errorMessage,
        unreadCount,
        hasReachedMax,
      ];
}