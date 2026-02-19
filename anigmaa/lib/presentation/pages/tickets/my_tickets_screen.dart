// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/ticket.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/tickets/tickets_bloc.dart';
import '../../bloc/tickets/tickets_event.dart';
import '../../bloc/tickets/tickets_state.dart';
import '../../../injection_container.dart' as di;
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = di.sl<AuthService>().userId ?? '';
    return BlocProvider(
      create: (_) => di.sl<TicketsBloc>()
        ..add(LoadUserTickets(userId)),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text(
            'Tiket Gue',
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
        body: BlocBuilder<TicketsBloc, TicketsState>(
          builder: (context, state) {
            if (state is TicketsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              );
            }

            if (state is TicketsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final uid = di.sl<AuthService>().userId ?? '';
                        context.read<TicketsBloc>().add(LoadUserTickets(uid));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            if (state is TicketsLoaded) {
              if (state.tickets.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.tickets.length,
                itemBuilder: (context, index) {
                  return _buildTicketCard(context, state.tickets[index]);
                },
              );
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: AppColors.border,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Tiket Nih',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiket yang lo beli bakal muncul di sini',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Ticket ticket) {
    final isCheckedIn = ticket.isCheckedIn;
    final isCancelled = ticket.status == TicketStatus.cancelled;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticket: ticket),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCancelled
                ? AppColors.border
                : AppColors.secondary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top section with event info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? AppColors.border
                              : isCheckedIn
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
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
                              size: 14,
                              color: isCancelled
                                  ? AppColors.textSecondary
                                  : isCheckedIn
                                      ? AppColors.success
                                      : AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCancelled
                                  ? 'DIBATALIN'
                                  : isCheckedIn
                                      ? 'UDAH CHECK-IN'
                                      : 'AKTIF',
                              style: AppTextStyles.label.copyWith(
                                color: isCancelled
                                    ? AppColors.textSecondary
                                    : isCheckedIn
                                        ? AppColors.success
                                        : AppColors.secondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (ticket.pricePaid > 0)
                        Text(
                          'Rp ${ticket.pricePaid.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyLargeBold,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'GRATIS',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Event title (placeholder - will get from event data)
                  Text(
                    'Nama Event',
                    style: AppTextStyles.bodyLargeBold.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Attendance code
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kode: ${ticket.attendanceCode}',
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Purchase date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dibeli ${_formatDate(ticket.purchasedAt)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isCheckedIn && ticket.checkedInAt != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Check-in ${_formatDate(ticket.checkedInAt!)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Dashed divider
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: DashedLinePainter(),
            ),
            // Bottom section with action
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isCancelled
                          ? 'Tiket ini udah dibatalin'
                          : isCheckedIn
                              ? 'Tiket ini udah kepake'
                              : 'Tap buat liat detail tiket',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: isCancelled ? FontStyle.italic : null,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
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
    return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
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
