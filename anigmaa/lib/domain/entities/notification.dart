import 'package:equatable/equatable.dart';

enum NotificationType {
  like,
  comment,
  follow,
  eventReminder,
  eventJoined,
  eventInvite,
  repost,
  mention,
}

class Notification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? avatarUrl;
  final String? actionUrl; // Deep link to related content
  final Map<String, dynamic>? metadata; // Additional data (user IDs, post IDs, etc.)

  const Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
    this.actionUrl,
    this.metadata,
  });

  Notification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? avatarUrl,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Notification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        timestamp,
        isRead,
        avatarUrl,
        actionUrl,
        metadata,
      ];
}
