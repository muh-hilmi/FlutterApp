// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/ticket.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TicketDetailScreen extends StatelessWidget {
  final Ticket ticket;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = ticket.isCheckedIn;
    final isCancelled = ticket.status == TicketStatus.cancelled;

    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Detail Tiket',
          style: AppTextStyles.h3,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Main ticket card with attendance code
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCancelled
                            ? [AppColors.border, AppColors.textTertiary]
                            : isCheckedIn
                                ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                                : [AppColors.secondary, const Color(0xFF6B7F3F)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCancelled
                                    ? Icons.cancel_outlined
                                    : isCheckedIn
                                        ? Icons.check_circle
                                        : Icons.confirmation_number,
                                size: 18,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isCancelled
                                    ? 'DIBATALIN'
                                    : isCheckedIn
                                        ? 'UDAH CHECK-IN'
                                        : 'TIKET VALID',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Attendance Code - BIG!
                        Text(
                          'Kode Kehadiran',
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: AppColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            ticket.attendanceCode,
                            style: AppTextStyles.display.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                              letterSpacing: 8,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Copy button
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: ticket.attendanceCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check, color: AppColors.white, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Kode udah disalin!'),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy,
                            size: 16,
                            color: AppColors.white,
                          ),
                          label: Text(
                            'Salin Kode',
                            style: AppTextStyles.bodyMediumBold.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dashed divider
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(),
                  ),
                  // Bottom section with details
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Info Tiket',
                          style: AppTextStyles.bodyLargeBold.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.event,
                          'Event',
                          'Nama Event', // Placeholder - will get from event
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.confirmation_number_outlined,
                          'Ticket ID',
                          '#${ticket.id.substring(0, 8).toUpperCase()}',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Dibeli',
                          _formatDate(ticket.purchasedAt),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.payments_outlined,
                          'Harga',
                          ticket.pricePaid > 0
                              ? 'Rp ${ticket.pricePaid.toStringAsFixed(0)}'
                              : 'GRATIS',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.receipt_outlined,
                          'Transaction ID',
                          'TRX-${ticket.id.substring(0, 8).toUpperCase()}',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.payment,
                          'Metode Bayar',
                          ticket.pricePaid > 0 ? 'Virtual Account' : 'Gratis',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.check_circle_outline,
                          'Status Bayar',
                          'Lunas',
                          iconColor: AppColors.success,
                        ),
                        if (isCheckedIn && ticket.checkedInAt != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.check_circle_outline,
                            'Check-In',
                            _formatDate(ticket.checkedInAt!),
                            iconColor: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Receipt actions
            if (ticket.pricePaid > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Download struk bentar lagi ya!'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download Struk'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bagiin struk bentar lagi ya!'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Bagiin Struk'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Instructions card
            if (!isCheckedIn && !isCancelled) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cara Check-In',
                          style: AppTextStyles.bodyLargeBold.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Tunjukin kode kehadiran ini ke host event\n'
                      '2. Host bakal masukin kode buat verifikasi tiket lo\n'
                      '3. Setelah diverifikasi, lo siap menikmati acaranya!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.info,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Contact support
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Add support contact
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Fitur kontak support bentar lagi ya!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.help_outline,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  'Butuh bantuan? Hubungi Support',
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} jam ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
