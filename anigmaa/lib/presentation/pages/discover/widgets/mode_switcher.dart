import 'package:flutter/material.dart';

class ModeSwitcher extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeChanged;

  const ModeSwitcher({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildModeChip(
            mode: 'trending',
            label: 'Trending',
            icon: Icons.local_fire_department,
            isActive: selectedMode == 'trending',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'for_you',
            label: 'For You',
            icon: Icons.person_outline,
            isActive: selectedMode == 'for_you',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'chill',
            label: 'Chill',
            icon: Icons.spa,
            isActive: selectedMode == 'chill',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'today',
            label: 'Hari Ini',
            icon: Icons.today_outlined,
            isActive: selectedMode == 'today',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'free',
            label: 'Gratis',
            icon: Icons.card_giftcard,
            isActive: selectedMode == 'free',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'paid',
            label: 'Bayar',
            icon: Icons.attach_money,
            isActive: selectedMode == 'paid',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'nearby',
            label: 'Dekat Lokasi',
            icon: Icons.location_on_outlined,
            isActive: selectedMode == 'nearby',
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String mode,
    required String label,
    required IconData icon,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFBBC863) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}