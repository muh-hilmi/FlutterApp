import 'package:flutter/material.dart';
import '../../../../domain/entities/event.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

class EventLocationCard extends StatelessWidget {
  final Event event;
  final VoidCallback onOpenMaps;

  const EventLocationCard({
    super.key,
    required this.event,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFBBC863),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenMaps,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFBBC863),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.location.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          ...[
            const SizedBox(height: 4),
            Text(
              event.location.address,
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
