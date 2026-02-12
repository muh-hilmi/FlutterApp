import 'package:flutter/material.dart';
import '../../domain/entities/event_attendee.dart';

/// Dialog for confirming manual check-in of an attendee
class CheckinDialog extends StatelessWidget {
  final EventAttendee attendee;

  const CheckinDialog({
    super.key,
    required this.attendee,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('checkin_dialog'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: attendee.avatar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            attendee.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Color(0xFFBBC863),
                                size: 32,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xFFBBC863),
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check-In Peserta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendee.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Ticket info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number,
                        size: 18,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tiket',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        attendee.ticketType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  if (attendee.checkedIn) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sudah Check-In',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (attendee.formattedCheckInTime != null)
                          Text(
                            attendee.formattedCheckInTime!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Confirmation message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: attendee.checkedIn
                    ? Colors.orange.withValues(alpha: 0.1)
                    : const Color(0xFFBBC863).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: attendee.checkedIn
                      ? Colors.orange.withValues(alpha: 0.3)
                      : const Color(0xFFBBC863).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    attendee.checkedIn ? Icons.info_outline : Icons.check_circle_outline,
                    color: attendee.checkedIn ? Colors.orange : const Color(0xFFBBC863),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      attendee.checkedIn
                          ? 'Peserta ini sudah check-in sebelumnya.'
                          : 'Konfirmasi check-in untuk peserta ini?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: attendee.checkedIn ? Colors.orange.shade900 : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('checkin_dialog_cancel_button'),
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('checkin_dialog_confirm_button'),
                    onPressed: attendee.checkedIn
                        ? null
                        : () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: attendee.checkedIn
                          ? Colors.grey
                          : const Color(0xFFBBC863),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      attendee.checkedIn ? 'Sudah Check-In' : 'Check-In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show check-in confirmation dialog
  static Future<bool?> show(BuildContext context, EventAttendee attendee) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CheckinDialog(attendee: attendee),
    );
  }
}
