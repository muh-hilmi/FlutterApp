import 'package:flutter/material.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';

/// Confirmation dialog for deleting an event
/// Validates that event can be deleted (0 attendees, upcoming status)
class DeleteEventDialog extends StatelessWidget {
  final Event event;

  const DeleteEventDialog({
    super.key,
    required this.event,
  });

  /// Check if event can be deleted
  bool get canDelete {
    return event.currentAttendees == 0 && event.status == EventStatus.upcoming;
  }

  /// Get reason why event cannot be deleted
  String get deleteRestrictionReason {
    if (event.currentAttendees > 0) {
      return 'Event ini sudah memiliki ${event.currentAttendees} peserta. Event dengan peserta tidak bisa dihapus.';
    }
    if (event.status != EventStatus.upcoming) {
      final statusText = event.status == EventStatus.ended
          ? 'sudah selesai'
          : event.status == EventStatus.ongoing
              ? 'sedang berlangsung'
              : 'sudah dibatalkan';
      return 'Event ini $statusText. Hanya event yang akan datang yang bisa dihapus.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('delete_event_dialog'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            canDelete ? Icons.warning_amber_rounded : Icons.block,
            color: canDelete ? Colors.orange : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canDelete ? 'Hapus Event?' : 'Tidak Bisa Hapus Event',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canDelete
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: canDelete ? Colors.orange : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      color: canDelete ? Colors.orange.shade900 : Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            canDelete
                ? 'Event yang dihapus tidak bisa dikembalikan lagi. Yakin ingin menghapus event ini?'
                : deleteRestrictionReason,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          if (!canDelete) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.currentAttendees > 0
                          ? 'Gunakan fitur edit untuk mengubah detail event.'
                          : 'Hubungi support jika butuh bantuan.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!canDelete)
          TextButton(
            key: const Key('delete_event_dialog_close_button'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBBC863),
              ),
            ),
          )
        else ...[
          TextButton(
            key: const Key('delete_event_dialog_cancel_button'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('delete_event_dialog_confirm_button'),
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Hapus',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Show delete confirmation dialog
  static Future<bool?> show(BuildContext context, Event event) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteEventDialog(event: event),
    );
  }
}
