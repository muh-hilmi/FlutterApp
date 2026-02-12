import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification.dart' as domain;
import '../../../domain/repositories/notification_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _notificationRepository;

  NotificationsBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(const NotificationsState.initial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));

    try {
      final notifications = await _notificationRepository.getNotifications(
        limit: 20,
        offset: 0,
      );

      final unreadCount = notifications.where((n) => !n.isRead).length;

      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        unreadCount: unreadCount,
        hasReachedMax: notifications.length < 20,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: _getErrorMessage(error),
      ));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationRepository.markNotificationAsRead(event.notificationId);

      final updatedNotifications = state.notifications.map((notification) {
        return notification.id == event.notificationId
            ? notification.copyWith(isRead: true)
            : notification;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ));
    } catch (error) {
      // Silent fail for mark as read - don't update state if API fails
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _notificationRepository.markAllNotificationsAsRead();

      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      emit(state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
    } catch (error) {
      // Silent fail for mark all as read
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.status == NotificationsStatus.refreshing) return;

    emit(state.copyWith(status: NotificationsStatus.refreshing));

    try {
      final notifications = await _notificationRepository.getNotifications(
        limit: 20,
        offset: 0,
      );

      final unreadCount = notifications.where((n) => !n.isRead).length;

      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        unreadCount: unreadCount,
        hasReachedMax: notifications.length < 20,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotificationsStatus.loaded, // Keep previous data on refresh error
        errorMessage: _getErrorMessage(error),
      ));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network') || error.toString().contains('connection')) {
      return 'Koneksi internet bermasalah. Cek koneksi kamu ya! 📡';
    } else if (error.toString().contains('timeout')) {
      return 'Server lagi lelet nih. Coba lagi yuk! ⏱️';
    } else if (error.toString().contains('401')) {
      return 'Sesi kamu habis. Yuk login lagi! 🔐';
    } else if (error.toString().contains('404')) {
      return 'Data ga ketemu. Mungkin udah dihapus 🤔';
    } else if (error.toString().contains('500')) {
      return 'Server lagi bermasalah. Tunggu sebentar ya! 🔧';
    } else {
      return 'Ada kendala nih. Coba lagi ya! 😅';
    }
  }
}