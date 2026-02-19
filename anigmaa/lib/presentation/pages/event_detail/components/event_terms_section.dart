import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventTermsSection extends StatelessWidget {
  const EventTermsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Syarat & Ketentuan',
          style: AppTextStyles.bodyLargeBold,
        ),
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.textSecondary,
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
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textEmphasis,
        height: 1.4,
      ),
    );
  }
}
