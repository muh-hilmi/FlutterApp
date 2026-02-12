part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();

  @override
  List<Object> get props => [];
}

class MarkAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class MarkAllAsRead extends NotificationsEvent {
  const MarkAllAsRead();

  @override
  List<Object> get props => [];
}

class RefreshNotifications extends NotificationsEvent {
  const RefreshNotifications();

  @override
  List<Object> get props => [];
}