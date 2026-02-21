// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

enum RefundStatus { processing, approved, rejected, completed, pendingInfo }

class RefundItem {
  final String id;
  final String eventName;
  final double amount;
  final RefundStatus status;
  final String requestDate;
  final String? reason;
  final String? completedDate;
  final String? rejectionReason;

  RefundItem({
    required this.id,
    required this.eventName,
    required this.amount,
    required this.status,
    required this.requestDate,
    this.reason,
    this.completedDate,
    this.rejectionReason,
  });
}

class RefundStatusScreen extends StatefulWidget {
  const RefundStatusScreen({super.key});

  @override
  State<RefundStatusScreen> createState() => _RefundStatusScreenState();
}

class _RefundStatusScreenState extends State<RefundStatusScreen> {
  // Mock data
  List<RefundItem> refunds = [
    RefundItem(
      id: '1',
      eventName: 'Konser Musik Jakarta',
      amount: 250000,
      status: RefundStatus.processing,
      requestDate: '20 Des 2025',
      reason: 'Event dibatalkan oleh host',
    ),
    RefundItem(
      id: '2',
      eventName: 'Workshop Design',
      amount: 150000,
      status: RefundStatus.completed,
      requestDate: '15 Des 2025',
      completedDate: '18 Des 2025',
      reason: 'Event dibatalkan oleh host',
    ),
    RefundItem(
      id: '3',
      eventName: 'Tech Meetup 2025',
      amount: 75000,
      status: RefundStatus.approved,
      requestDate: '10 Des 2025',
      reason: 'Pengajuan refund',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildRefundSummary(),
            Expanded(
              child: refunds.isEmpty ? _buildEmptyState() : _buildRefundList(),
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
        border: Border(bottom: BorderSide(color: AppColors.surfaceAlt)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Status Refund',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.helpCircle),
            onPressed: _showHelpBottomSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSummary() {
    final processingAmount = refunds
        .where(
          (r) =>
              r.status == RefundStatus.processing ||
              r.status == RefundStatus.approved,
        )
        .fold<double>(0, (sum, r) => sum + r.amount);

    final completedAmount = refunds
        .where((r) => r.status == RefundStatus.completed)
        .fold<double>(0, (sum, r) => sum + r.amount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFBBC863), const Color(0xFF9DA953)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Refund',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${_formatAmount(completedAmount)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (processingAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Rp ${_formatAmount(processingAmount)} sedang diproses',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
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
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.refreshCw,
              size: 48,
              color: AppColors.border,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Refund',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textEmphasis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Refund akan muncul di sini jika ada pembatalan',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: refunds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildRefundCard(refunds[index]);
      },
    );
  }

  Widget _buildRefundCard(RefundItem refund) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        refund.eventName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatAmount(refund.amount)}',
                        style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(refund.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.surfaceAlt),
            const SizedBox(height: 12),
            _buildRefundDetails(refund),
            if (refund.status == RefundStatus.rejected ||
                refund.status == RefundStatus.pendingInfo) ...[
              const SizedBox(height: 12),
              _buildActionButtons(refund),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(RefundStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (status) {
      case RefundStatus.processing:
        backgroundColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        label = 'Diproses';
        icon = LucideIcons.loader;
        break;
      case RefundStatus.approved:
        backgroundColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        label = 'Disetujui';
        icon = LucideIcons.checkCircle;
        break;
      case RefundStatus.completed:
        backgroundColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        label = 'Selesai';
        icon = LucideIcons.checkCircle2;
        break;
      case RefundStatus.rejected:
        backgroundColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        label = 'Ditolak';
        icon = LucideIcons.xCircle;
        break;
      case RefundStatus.pendingInfo:
        backgroundColor = const Color(0xFFFFE8CC);
        textColor = const Color(0xFFD46B08);
        label = 'Info Diperlukan';
        icon = LucideIcons.alertTriangle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundDetails(RefundItem refund) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(LucideIcons.calendar, 'Diajukan', refund.requestDate),
        if (refund.completedDate != null)
          _buildDetailRow(
            LucideIcons.checkCircle,
            'Selesai',
            refund.completedDate!,
          ),
        if (refund.reason != null)
          _buildDetailRow(LucideIcons.alignLeft, 'Alasan', refund.reason!),
        if (refund.rejectionReason != null)
          _buildDetailRow(
            LucideIcons.xCircle,
            'Penolakan',
            refund.rejectionReason!,
            isNegative: true,
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isNegative ? Colors.red[400] : AppColors.textDisabled,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isNegative ? Colors.red[600] : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RefundItem refund) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showDetailModal(refund),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Detail', style: TextStyle(fontSize: 13)),
          ),
        ),
        if (refund.status == RefundStatus.rejected) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _appealRefund,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBC863),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Ajukan Banding',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
        if (refund.status == RefundStatus.pendingInfo) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _provideInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBC863),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Lengkapi Info',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showDetailModal(RefundItem refund) {
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
              'Detail Refund',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildModalDetailRow('ID Refund', refund.id),
            _buildModalDetailRow('Nama Event', refund.eventName),
            _buildModalDetailRow(
              'Jumlah',
              'Rp ${_formatAmount(refund.amount)}',
            ),
            _buildModalDetailRow('Tanggal Pengajuan', refund.requestDate),
            if (refund.completedDate != null)
              _buildModalDetailRow('Tanggal Selesai', refund.completedDate!),
            if (refund.reason != null)
              _buildModalDetailRow('Alasan', refund.reason!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBC863),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _appealRefund() {
    // Navigate to appeal form or show appeal modal
  }

  void _provideInfo() {
    // Navigate to info form
  }

  void _showHelpBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bantuan Refund',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildHelpItem('Waktu Proses', '1-7 hari kerja'),
            _buildHelpItem('Metode Refund', 'Sama dengan metode pembayaran'),
            _buildHelpItem('Biaya Admin', 'Gratis untuk pembatalan oleh host'),
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

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.info,
              size: 16,
              color: const Color(0xFFBBC863),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
