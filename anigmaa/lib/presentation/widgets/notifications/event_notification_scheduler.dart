import 'package:flutter/material.dart';
import '../common/snackbar_helper.dart';

/// Event notification scheduler
///
/// Schedules notifications for:
/// - H-1: 24 hours before event
/// - H-0: 3-4 hours before event
class EventNotificationScheduler {
  // Channel constants for future notification implementation
  // static const String _notificationChannelId = 'event_reminders';
  // static const String _notificationChannelName = 'Event Reminders';
  // static const String _notificationChannelDescription = 'Notifications for upcoming events';

  /// Schedule all reminders for an event
  static Future<void> scheduleEventReminders({
    required String eventId,
    required String eventName,
    required DateTime eventStartTime,
    required String? eventLocation,
  }) async {
    // H-1: 24 hours before
    final h1ReminderTime = eventStartTime.subtract(const Duration(hours: 24));
    if (h1ReminderTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _generateNotificationId(eventId, 'h1'),
        title: 'Event Reminder',
        body: '$eventName\nBesok jam ${eventStartTime.hour}:${eventStartTime.minute.toString().padLeft(2, '0')}',
        scheduledTime: h1ReminderTime,
      );
    }

    // H-0: 3-4 hours before
    final h0ReminderTime = eventStartTime.subtract(const Duration(hours: 3));
    if (h0ReminderTime.isAfter(DateTime.now())) {
      final socialCopy = _getSocialCopy();
      await _scheduleNotification(
        id: _generateNotificationId(eventId, 'h0'),
        title: 'Segera! Event mulai sebentar',
        body: '$eventName\nDalam 3 jam lagi\n$socialCopy',
        scheduledTime: h0ReminderTime,
      );
    }
  }

  /// Cancel all reminders for an event
  static Future<void> cancelEventReminders(String eventId) async {
    // TODO: Implement cancel notification logic
    // This would use flutter_local_notifications to cancel specific notifications
  }

  /// Show immediate notification (e.g., after payment confirmation)
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    // TODO: Implement immediate notification
  }

  static String _getSocialCopy() {
    final copies = [
      '3 orang lain juga akan ke event ini!',
      'Masih ada temen yang bisa kamu ajak bareng',
      'Jangan lupa tiket ya!',
    ];
    return copies[DateTime.now().millisecond % copies.length];
  }

  static int _generateNotificationId(String eventId, String suffix) {
    return '$eventId-$suffix'.hashCode;
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // TODO: Implement actual notification scheduling
    // This would use flutter_local_notifications package
    debugPrint('Notification scheduled: $id - $title at $scheduledTime');
  }

  /// Create notification channel (call once on app startup)
  static Future<void> initialize() async {
    // TODO: Initialize notification channel
    debugPrint('Event notification scheduler initialized');
  }
}

/// Simple in-app notification display
class EventNotification {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    SnackBarHelper.showInfo(
      context,
      message,
      duration: duration,
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    VoidCallback? onAction,
  }) {
    SnackBarHelper.showSuccess(
      context,
      message,
      actionLabel: onAction != null ? 'LIHAT' : null,
      onActionPressed: onAction,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
  }) {
    SnackBarHelper.showError(
      context,
      message,
    );
  }
}

/// Ticket status enum
enum TicketStatus {
  upcoming,
  today,
  completed,
}

/// Notification styles for different event statuses
class EventNotificationStyles {
  static String getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.upcoming:
        return 'AKTIF';
      case TicketStatus.today:
        return 'HARI INI';
      case TicketStatus.completed:
        return 'SELESAI';
    }
  }

  static IconData getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.upcoming:
        return Icons.confirmation_number_rounded;
      case TicketStatus.today:
        return Icons.event_available_rounded;
      case TicketStatus.completed:
        return Icons.check_circle_rounded;
    }
  }
}
