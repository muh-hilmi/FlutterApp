// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/ticket.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/tickets/tickets_bloc.dart';
import '../../bloc/tickets/tickets_event.dart';
import '../../bloc/tickets/tickets_state.dart';
import '../../../injection_container.dart' as di;

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Ticket _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
  }

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = _currentTicket.isCheckedIn;
    final isCancelled = _currentTicket.status == TicketStatus.cancelled;
    final isFree = _currentTicket.isFree;

    // Cancel rules:
    // - FREE events: can cancel (auto cancel, no refund)
    // - PAID events: CANNOT cancel
    bool canCancel = !isCheckedIn && !isCancelled && isFree;

    // Also check if event hasn't started yet
    if (_currentTicket.eventStartTime != null) {
      final eventHasStarted = DateTime.now().isAfter(_currentTicket.eventStartTime!);
      canCancel = canCancel && !eventHasStarted;
    }

    return BlocProvider.value(
      value: di.sl<TicketsBloc>(),
      child: BlocListener<TicketsBloc, TicketsState>(
        listener: (context, state) {
          if (state is TicketCancelled) {
            setState(() {
              _currentTicket = state.ticket;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tiket berhasil dibatalkan'),
                backgroundColor: AppColors.info,
              ),
            );
            // Navigate back and signal that ticket was cancelled
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(context, true); // true = ticket cancelled
              }
            });
          } else if (state is TicketsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal: ${state.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Scaffold(
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
                        // QR Code + Attendance Code
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // QR Code
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: QrImageView(
                                  data: _currentTicket.attendanceCode,
                                  version: QrVersions.auto,
                                  size: 80,
                                  backgroundColor: AppColors.white,
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Attendance Code - smaller
                              Column(
                                children: [
                                  Text(
                                    'Kode',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentTicket.attendanceCode,
                                    style: AppTextStyles.display.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.secondary,
                                      letterSpacing: 4,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Copy button
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _currentTicket.attendanceCode),
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
                          _currentTicket.eventTitle ?? 'Nama Event',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.confirmation_number_outlined,
                          'Ticket ID',
                          _currentTicket.id.substring(0, 8).toUpperCase(),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.qr_code_2_outlined,
                          'Kode Check-In',
                          _currentTicket.attendanceCode,
                          iconColor: AppColors.secondary,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Dibeli',
                          _formatDateLocal(_currentTicket.purchasedAt),
                        ),
                        const SizedBox(height: 12),
                        if (_currentTicket.eventStartTime != null)
                          _buildInfoRow(
                            Icons.schedule,
                            'Waktu Event',
                            _formatDateLocal(_currentTicket.eventStartTime!),
                          ),
                        if (_currentTicket.eventStartTime != null) const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.payments_outlined,
                          'Harga',
                          _currentTicket.pricePaid > 0
                              ? 'Rp ${_currentTicket.pricePaid.toStringAsFixed(0)}'
                              : 'GRATIS',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.payment,
                          'Metode Bayar',
                          _currentTicket.pricePaid > 0 ? 'Midtrans' : 'Gratis',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.check_circle_outline,
                          'Status',
                          _getStatusText(),
                          iconColor: _getStatusColor(),
                        ),
                        if (isCheckedIn && _currentTicket.checkedInAt != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.check_circle_outline,
                            'Check-In',
                            _formatDateLocal(_currentTicket.checkedInAt!),
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
            if (_currentTicket.pricePaid > 0) ...[
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
            // Cancel Ticket Button (only if allowed)
            if (canCancel)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Batal Tiket'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            if (!isCheckedIn && !isCancelled) const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          'Batalkan Tiket?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Kamu yakin mau batalkan tiket gratis ini? Tindakan ini tidak bisa dibatalkan.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TicketsBloc>().add(CancelTicketRequested(_currentTicket.id));
            },
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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

  String _formatDateLocal(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('d MMM yyyy, HH:mm').format(localDate);
  }

  String _getStatusText() {
    if (_currentTicket.status == TicketStatus.cancelled) return 'Dibatalkan';
    if (_currentTicket.isCheckedIn) return 'Sudah Check-In';
    return 'Aktif';
  }

  Color _getStatusColor() {
    if (_currentTicket.status == TicketStatus.cancelled) return AppColors.error;
    if (_currentTicket.isCheckedIn) return AppColors.success;
    return AppColors.secondary;
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
