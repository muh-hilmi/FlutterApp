// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum WaitlistStatus { waiting, movedUp, spotAvailable, expired }

class WaitlistItem {
  final String id;
  final String eventName;
  final String eventDate;
  final String eventImage;
  final int position;
  final WaitlistStatus status;
  final int totalSpots;

  WaitlistItem({
    required this.id,
    required this.eventName,
    required this.eventDate,
    required this.eventImage,
    required this.position,
    required this.status,
    required this.totalSpots,
  });
}

class EventWaitlistScreen extends StatefulWidget {
  final String? eventId;

  const EventWaitlistScreen({super.key, this.eventId});

  @override
  State<EventWaitlistScreen> createState() => _EventWaitlistScreenState();
}

class _EventWaitlistScreenState extends State<EventWaitlistScreen> {
  // Mock data
  List<WaitlistItem> waitlistItems = [
    WaitlistItem(
      id: '1',
      eventName: 'Konser Musik Jakarta',
      eventDate: '25 Des 2025',
      eventImage: '',
      position: 3,
      status: WaitlistStatus.waiting,
      totalSpots: 50,
    ),
    WaitlistItem(
      id: '2',
      eventName: 'Workshop Design Thinking',
      eventDate: '28 Des 2025',
      eventImage: '',
      position: 1,
      status: WaitlistStatus.spotAvailable,
      totalSpots: 20,
    ),
    WaitlistItem(
      id: '3',
      eventName: 'Tech Meetup 2025',
      eventDate: '30 Des 2025',
      eventImage: '',
      position: 15,
      status: WaitlistStatus.movedUp,
      totalSpots: 100,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: waitlistItems.isEmpty
                  ? _buildEmptyState()
                  : _buildWaitlistList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Daftar Tunggu Saya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: _showInfoBottomSheet,
            icon: const Icon(LucideIcons.info, size: 16),
            label: const Text('Info'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBBC863),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.userX2, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada di Daftar Tunggu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Event yang penuh akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitlistList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: waitlistItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildWaitlistCard(waitlistItems[index]);
      },
    );
  }

  Widget _buildWaitlistCard(WaitlistItem item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(LucideIcons.calendar, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.eventDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusBadge(item),
            const SizedBox(height: 12),
            _buildPositionIndicator(item),
            if (item.status == WaitlistStatus.spotAvailable) ...[
              const SizedBox(height: 12),
              _buildClaimButton(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(WaitlistItem item) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (item.status) {
      case WaitlistStatus.waiting:
        backgroundColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        label = 'Menunggu';
        icon = LucideIcons.clock;
        break;
      case WaitlistStatus.movedUp:
        backgroundColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        label = 'Naik Peringkat!';
        icon = LucideIcons.trendingUp;
        break;
      case WaitlistStatus.spotAvailable:
        backgroundColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        label = 'Tiket Tersedia!';
        icon = LucideIcons.ticket;
        break;
      case WaitlistStatus.expired:
        backgroundColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        label = 'Kedaluwarsa';
        icon = LucideIcons.xCircle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionIndicator(WaitlistItem item) {
    final progress = item.position / item.totalSpots;
    final remaining = item.totalSpots - item.position;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Posisi Anda: #${item.position}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '$remaining orang di depan Anda',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1 - progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              item.status == WaitlistStatus.spotAvailable
                  ? const Color(0xFFBBC863)
                  : Colors.orange,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildClaimButton(WaitlistItem item) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _claimSpot(item),
        icon: const Icon(LucideIcons.ticket, size: 16),
        label: const Text('Klaim Tiket Sekarang'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBBC863),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _claimSpot(WaitlistItem item) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4EDDA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                size: 32,
                color: Color(0xFF155724),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tiket Tersedia!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Satu tiket untuk "${item.eventName}" telah tersedia. Anda memiliki 24 jam untuk klaim.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Lewati'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to payment
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBBC863),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Bayar Sekarang'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tentang Daftar Tunggu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              LucideIcons.bell,
              'Notifikasi',
              'Anda akan menerima notifikasi saat tiket tersedia.',
            ),
            _buildInfoItem(
              LucideIcons.clock,
              'Waktu Klaim',
              'Tiket harus diklaim dalam 24 jam setelah notifikasi.',
            ),
            _buildInfoItem(
              LucideIcons.users,
              'Prioritas',
              'Posisi didasarkan pada waktu bergabung.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBC863),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFBBC863)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
