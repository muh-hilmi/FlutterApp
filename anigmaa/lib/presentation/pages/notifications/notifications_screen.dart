import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../domain/entities/notification.dart' as domain;
import '../../bloc/notifications/notifications_bloc.dart';
import '../../../injection_container.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications from API when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsBloc>().add(LoadNotifications());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NotificationsBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(width: 8),
              BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, state) {
                  if (state.unreadCount > 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBC863),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF000000)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state.unreadCount > 0) {
                  return TextButton(
                    onPressed: () {
                      context.read<NotificationsBloc>().add(MarkAllAsRead());
                    },
                    child: const Text(
                      'Tandai semua dibaca',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBBC863),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state.status == NotificationsStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFBBC863),
                  strokeWidth: 3,
                ),
              );
            }

            if (state.status == NotificationsStatus.error) {
              return _buildErrorState(state.errorMessage ?? 'Terjadi kesalahan');
            }

            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationsBloc>().add(RefreshNotifications());
              },
              color: const Color(0xFFBBC863),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationItem(state.notifications[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildNotificationItem(domain.Notification notification) {
    return Container(
      color: notification.isRead ? Colors.white : const Color(0xFFFCFCFC),
      child: InkWell(
        onTap: () {
          // Mark notification as read via API
          if (!notification.isRead) {
            context.read<NotificationsBloc>().add(MarkAsRead(notification.id));
          }

          // Navigate to actionUrl or handle specific notification types
          _handleNotificationTap(notification);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' ${notification.message}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.timestamp, locale: 'en_short'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFBBC863),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFBBC863)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Color(0xFF2D3142)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<NotificationsBloc>().add(LoadNotifications());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔔',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi nih',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(domain.Notification notification) {
    // Handle different notification types with appropriate navigation
    switch (notification.type) {
      case domain.NotificationType.like:
      case domain.NotificationType.comment:
      case domain.NotificationType.mention:
        if (notification.metadata?['post_id'] != null) {
          // Navigate to post detail
          // TODO: Implement navigation to post detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Membuka postingan...'),
              backgroundColor: const Color(0xFFBBC863),
            ),
          );
        }
        break;

      case domain.NotificationType.follow:
        if (notification.metadata?['user_id'] != null) {
          // Navigate to user profile
          // TODO: Implement navigation to user profile
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Membuka profil pengguna...'),
              backgroundColor: const Color(0xFFBBC863),
            ),
          );
        }
        break;

      case domain.NotificationType.eventReminder:
      case domain.NotificationType.eventJoined:
      case domain.NotificationType.eventInvite:
        if (notification.metadata?['event_id'] != null) {
          // Navigate to event detail
          // TODO: Implement navigation to event detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Membuka detail event...'),
              backgroundColor: const Color(0xFFBBC863),
            ),
          );
        }
        break;

      case domain.NotificationType.repost:
        if (notification.metadata?['post_id'] != null) {
          // Navigate to post detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Membuka repost...'),
              backgroundColor: const Color(0xFFBBC863),
            ),
          );
        }
        break;
    }
  }

  IconData _getNotificationIcon(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.like:
        return Icons.favorite;
      case domain.NotificationType.comment:
        return Icons.chat_bubble;
      case domain.NotificationType.follow:
        return Icons.person_add;
      case domain.NotificationType.eventReminder:
        return Icons.event;
      case domain.NotificationType.eventJoined:
        return Icons.check_circle;
      case domain.NotificationType.eventInvite:
        return Icons.mail;
      case domain.NotificationType.repost:
        return Icons.repeat;
      case domain.NotificationType.mention:
        return Icons.alternate_email;
    }
  }

  Color _getNotificationColor(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.like:
        return Colors.red;
      case domain.NotificationType.comment:
        return Colors.blue;
      case domain.NotificationType.follow:
        return const Color(0xFFBBC863);
      case domain.NotificationType.eventReminder:
        return Colors.orange;
      case domain.NotificationType.eventJoined:
        return const Color(0xFFBBC863);
      case domain.NotificationType.eventInvite:
        return Colors.purple;
      case domain.NotificationType.repost:
        return const Color(0xFFBBC863);
      case domain.NotificationType.mention:
        return Colors.deepPurple;
    }
  }
}

// NOTE: Notification entity and NotificationType enum are now in domain layer
// See: lib/domain/entities/notification.dart
// See: lib/data/models/notification_model.dart
