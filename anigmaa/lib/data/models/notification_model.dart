import '../../domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    required super.timestamp,
    super.isRead = false,
    super.avatarUrl,
    super.actionUrl,
    super.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: _parseNotificationType(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      actionUrl: json['action_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _notificationTypeToString(type),
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'avatar_url': avatarUrl,
      'action_url': actionUrl,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromEntity(Notification notification) {
    return NotificationModel(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      timestamp: notification.timestamp,
      isRead: notification.isRead,
      avatarUrl: notification.avatarUrl,
      actionUrl: notification.actionUrl,
      metadata: notification.metadata,
    );
  }

  Notification toEntity() {
    return Notification(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead,
      avatarUrl: avatarUrl,
      actionUrl: actionUrl,
      metadata: metadata,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'event_reminder':
      case 'eventreminder':
        return NotificationType.eventReminder;
      case 'event_joined':
      case 'eventjoined':
        return NotificationType.eventJoined;
      case 'event_invite':
      case 'eventinvite':
        return NotificationType.eventInvite;
      case 'repost':
        return NotificationType.repost;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.like; // Default fallback
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.eventReminder:
        return 'event_reminder';
      case NotificationType.eventJoined:
        return 'event_joined';
      case NotificationType.eventInvite:
        return 'event_invite';
      case NotificationType.repost:
        return 'repost';
      case NotificationType.mention:
        return 'mention';
    }
  }
}
