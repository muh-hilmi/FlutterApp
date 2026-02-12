import 'package:flutter/material.dart';

class EventTermsSection extends StatelessWidget {
  const EventTermsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Syarat & Ketentuan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        iconColor: const Color(0xFFBBC863),
        collapsedIconColor: Colors.grey[600],
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTermItem(
                  '🎟️ Tiket yang sudah dibeli tidak dapat dikembalikan (non-refundable).',
                ),
                const SizedBox(height: 8),
                _buildTermItem(
                  '🕒 Harap datang 30 menit sebelum acara dimulai.',
                ),
                const SizedBox(height: 8),
                _buildTermItem(
                  '🚫 Dilarang membawa makanan dan minuman dari luar.',
                ),
                const SizedBox(height: 8),
                _buildTermItem(
                  '👮 Patuhi protokol keamanan dan ketertiban selama acara.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF333333),
        height: 1.4,
      ),
    );
  }
}
