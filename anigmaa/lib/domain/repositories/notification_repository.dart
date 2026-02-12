import '../../../domain/entities/notification.dart' as domain;

abstract class NotificationRepository {
  /// Get notifications for current user
  Future<List<domain.Notification>> getNotifications({
    int limit = 20,
    int offset = 0,
  });

  /// Mark a specific notification as read
  Future<void> markNotificationAsRead(String notificationId);

  /// Mark all notifications as read for current user
  Future<void> markAllNotificationsAsRead();

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount();
}