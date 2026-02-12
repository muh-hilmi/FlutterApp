import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/event.dart';

class EventDateTimeCard extends StatelessWidget {
  final Event event;

  const EventDateTimeCard({super.key, required this.event});

  String _getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Comprehensive timezone debugging
    final now = DateTime.now();
    final nowUtc = DateTime.now().toUtc();
    final localStartTime = event.startTime.toLocal();

    print('[EventDateTimeCard] === TIMEZONE DIAGNOSTICS ===');
    print('[EventDateTimeCard] Current LOCAL time: $now (offset: ${now.timeZoneOffset})');
    print('[EventDateTimeCard] Current UTC time: $nowUtc');
    print('[EventDateTimeCard] Device timezone offset: ${now.timeZoneOffset} hours = ${now.timeZoneOffset.inHours}h ${now.timeZoneOffset.inMinutes % 60}m');
    print('[EventDateTimeCard] Event startTime raw: ${event.startTime} (isUtc: ${event.startTime.isUtc})');
    print('[EventDateTimeCard] Event startTime.toLocal(): $localStartTime (isUtc: ${localStartTime.isUtc})');
    print('[EventDateTimeCard] Formatted time (HH:mm): ${DateFormat('HH:mm').format(localStartTime)}');
    print('[EventDateTimeCard] Expected: 19:00 if device is WIB (UTC+7)');
    print('[EventDateTimeCard] === END DIAGNOSTICS ===');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBBC863).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(event.startTime.toLocal()),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBBC863),
                  ),
                ),
                Text(
                  DateFormat('dd').format(event.startTime.toLocal()),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFBBC863),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayName(event.startTime.toLocal()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('HH:mm').format(event.startTime.toLocal())} - ${DateFormat('HH:mm').format(event.endTime.toLocal())}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
