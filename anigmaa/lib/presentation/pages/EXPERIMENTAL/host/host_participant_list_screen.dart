// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum PaymentStatus { paid, pending, failed, refunded, waitlist }

enum CheckInStatus { notCheckedIn, checkedIn, lateCheckIn }

class Participant {
  final String id;
  final String name;
  final String? avatar;
  final String email;
  final PaymentStatus paymentStatus;
  final CheckInStatus checkInStatus;
  final String? ticketType;
  final DateTime? checkInTime;
  final String joinDate;

  Participant({
    required this.id,
    required this.name,
    this.avatar,
    required this.email,
    required this.paymentStatus,
    this.checkInStatus = CheckInStatus.notCheckedIn,
    this.ticketType,
    this.checkInTime,
    required this.joinDate,
  });
}

class HostParticipantListScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const HostParticipantListScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<HostParticipantListScreen> createState() =>
      _HostParticipantListScreenState();
}

class _HostParticipantListScreenState extends State<HostParticipantListScreen> {
  PaymentStatus? _filterStatus;
  CheckInStatus? _filterCheckIn;
  String _searchQuery = '';
  bool _isSortDesc = true;

  // Mock participants
  List<Participant> participants = [
    Participant(
      id: '1',
      name: 'Ahmad Rizky',
      email: 'ahmad@email.com',
      paymentStatus: PaymentStatus.paid,
      checkInStatus: CheckInStatus.checkedIn,
      ticketType: 'VIP',
      joinDate: '10 Des 2025',
    ),
    Participant(
      id: '2',
      name: 'Budi Santoso',
      email: 'budi@email.com',
      paymentStatus: PaymentStatus.paid,
      checkInStatus: CheckInStatus.notCheckedIn,
      ticketType: 'Regular',
      joinDate: '11 Des 2025',
    ),
    Participant(
      id: '3',
      name: 'Citra Dewi',
      email: 'citra@email.com',
      paymentStatus: PaymentStatus.pending,
      checkInStatus: CheckInStatus.notCheckedIn,
      ticketType: 'Early Bird',
      joinDate: '12 Des 2025',
    ),
    Participant(
      id: '4',
      name: 'Dimas Pratama',
      email: 'dimas@email.com',
      paymentStatus: PaymentStatus.paid,
      checkInStatus: CheckInStatus.checkedIn,
      ticketType: 'Regular',
      joinDate: '12 Des 2025',
    ),
    Participant(
      id: '5',
      name: 'Eka Putri',
      email: 'eka@email.com',
      paymentStatus: PaymentStatus.refunded,
      checkInStatus: CheckInStatus.notCheckedIn,
      ticketType: 'VIP',
      joinDate: '10 Des 2025',
    ),
  ];

  List<Participant> get _filteredParticipants {
    var filtered = participants.toList();

    if (_filterStatus != null) {
      filtered = filtered
          .where((p) => p.paymentStatus == _filterStatus)
          .toList();
    }

    if (_filterCheckIn != null) {
      filtered = filtered
          .where((p) => p.checkInStatus == _filterCheckIn)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.email.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsRow(),
            _buildSearchAndFilter(),
            Expanded(
              child: _filteredParticipants.isEmpty
                  ? _buildEmptyState()
                  : _buildParticipantsList(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peserta Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.eventName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.qrCode),
            onPressed: _openScanner,
            tooltip: 'Scan QR',
          ),
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: _exportData,
            tooltip: 'Export',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = participants.length;
    final paid = participants
        .where((p) => p.paymentStatus == PaymentStatus.paid)
        .length;
    final checkedIn = participants
        .where((p) => p.checkInStatus == CheckInStatus.checkedIn)
        .length;
    final pending = participants
        .where((p) => p.paymentStatus == PaymentStatus.pending)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total', '$total', LucideIcons.users, Colors.grey),
          const SizedBox(width: 8),
          _buildStatCard(
            'Paid',
            '$paid',
            LucideIcons.checkCircle,
            const Color(0xFF155724),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Check-in',
            '$checkedIn',
            LucideIcons.scanLine,
            const Color(0xFFBBC863),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Pending',
            '$pending',
            LucideIcons.clock,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama atau email...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal),
            onPressed: _showFilterBottomSheet,
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredParticipants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildParticipantCard(_filteredParticipants[index]);
      },
    );
  }

  Widget _buildParticipantCard(Participant participant) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showParticipantDetail(participant),
        onLongPress: () => _showParticipantMenu(participant),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                child: Text(
                  participant.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _buildPaymentStatusChip(participant.paymentStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (participant.ticketType != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFBBC863,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              participant.ticketType!,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Icon(
                          LucideIcons.calendar,
                          size: 10,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          participant.joinDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildCheckInBadge(participant.checkInStatus),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case PaymentStatus.paid:
        backgroundColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        label = 'Paid';
        break;
      case PaymentStatus.pending:
        backgroundColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        label = 'Pending';
        break;
      case PaymentStatus.failed:
        backgroundColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        label = 'Failed';
        break;
      case PaymentStatus.refunded:
        backgroundColor = const Color(0xFFE2E3E5);
        textColor = const Color(0xFF383D41);
        label = 'Refunded';
        break;
      case PaymentStatus.waitlist:
        backgroundColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        label = 'Waitlist';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCheckInBadge(CheckInStatus status) {
    if (status == CheckInStatus.notCheckedIn) {
      return const SizedBox.shrink();
    }

    Color color = status == CheckInStatus.checkedIn
        ? const Color(0xFF155724)
        : Colors.orange;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          status == CheckInStatus.checkedIn
              ? LucideIcons.checkCircle
              : LucideIcons.alertCircle,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          status == CheckInStatus.checkedIn ? 'Checked-in' : 'Late',
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Peserta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _filterStatus != null || _filterCheckIn != null
                ? 'Coba ubah filter pencarian'
                : 'Belum ada yang bergabung',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Peserta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Status Pembayaran',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Semua', null, setModalState),
                  _buildFilterChip('Paid', PaymentStatus.paid, setModalState),
                  _buildFilterChip(
                    'Pending',
                    PaymentStatus.pending,
                    setModalState,
                  ),
                  _buildFilterChip(
                    'Refunded',
                    PaymentStatus.refunded,
                    setModalState,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Status Check-in',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    'Semua',
                    null,
                    setModalState,
                    isCheckIn: true,
                  ),
                  _buildFilterChip(
                    'Checked-in',
                    CheckInStatus.checkedIn,
                    setModalState,
                    isCheckIn: true,
                  ),
                  _buildFilterChip(
                    'Belum',
                    CheckInStatus.notCheckedIn,
                    setModalState,
                    isCheckIn: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _filterStatus = null;
                          _filterCheckIn = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Keep filter from modal
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBBC863),
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    dynamic value,
    StateSetter setModalState, {
    bool isCheckIn = false,
  }) {
    final isSelected = isCheckIn
        ? _filterCheckIn == value
        : _filterStatus == value;

    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          if (isCheckIn) {
            _filterCheckIn = selected ? value as CheckInStatus? : null;
          } else {
            _filterStatus = selected ? value as PaymentStatus? : null;
          }
        });
      },
      selectedColor: const Color(0xFFBBC863).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFFBBC863),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFBBC863) : Colors.grey[700],
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFBBC863) : Colors.grey[300]!,
      ),
    );
  }

  void _showParticipantDetail(Participant participant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey[200],
              child: Text(
                participant.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              participant.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              participant.email,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Tiket', participant.ticketType ?? '-'),
                  _buildDetailRow(
                    'Status',
                    _getPaymentStatusLabel(participant.paymentStatus),
                  ),
                  _buildDetailRow(
                    'Check-in',
                    _getCheckInStatusLabel(participant.checkInStatus),
                  ),
                  _buildDetailRow('Bergabung', participant.joinDate),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.messageCircle, size: 16),
                    label: const Text('Kontak'),
                  ),
                ),
                const SizedBox(width: 8),
                if (participant.checkInStatus == CheckInStatus.notCheckedIn &&
                    participant.paymentStatus == PaymentStatus.paid)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _manualCheckIn(participant),
                      icon: const Icon(LucideIcons.scanLine, size: 16),
                      label: const Text('Check-in'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBBC863),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showParticipantMenu(Participant participant) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.eye),
              title: const Text('Lihat Detail'),
              onTap: () {
                Navigator.pop(context);
                _showParticipantDetail(participant);
              },
            ),
            if (participant.paymentStatus == PaymentStatus.paid &&
                participant.checkInStatus == CheckInStatus.notCheckedIn)
              ListTile(
                leading: const Icon(LucideIcons.scanLine),
                title: const Text('Check-in Manual'),
                onTap: () {
                  Navigator.pop(context);
                  _manualCheckIn(participant);
                },
              ),
            if (participant.paymentStatus == PaymentStatus.pending)
              ListTile(
                leading: const Icon(LucideIcons.bell),
                title: const Text('Kirim Pengingat'),
                onTap: () {
                  Navigator.pop(context);
                  _sendReminder(participant);
                },
              ),
            ListTile(
              leading: const Icon(LucideIcons.mail),
              title: const Text('Kirim Email'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _manualCheckIn(Participant participant) {
    // Implement manual check-in
  }

  void _sendReminder(Participant participant) {
    // Send payment reminder
  }

  void _openScanner() {
    // Navigate to QR scanner
  }

  void _exportData() {
    // Export participant list to CSV
  }

  String _getPaymentStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Lunas';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Gagal';
      case PaymentStatus.refunded:
        return 'Refund';
      case PaymentStatus.waitlist:
        return 'Waitlist';
    }
  }

  String _getCheckInStatusLabel(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.notCheckedIn:
        return 'Belum';
      case CheckInStatus.checkedIn:
        return 'Sudah';
      case CheckInStatus.lateCheckIn:
        return 'Terlambat';
    }
  }
}
