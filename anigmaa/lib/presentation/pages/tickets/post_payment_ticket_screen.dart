import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'my_tickets_screen.dart';
import '../../pages/discover/swipeable_events_screen.dart';
import '../../widgets/notifications/event_notification_scheduler.dart'
    show EventNotificationScheduler, TicketStatus;

import '../../widgets/common/snackbar_helper.dart';

class PostPaymentTicketScreen extends StatefulWidget {
  final Event event;
  final String? ticketId;

  const PostPaymentTicketScreen({
    super.key,
    required this.event,
    this.ticketId,
  });

  @override
  State<PostPaymentTicketScreen> createState() =>
      _PostPaymentTicketScreenState();
}

class _PostPaymentTicketScreenState extends State<PostPaymentTicketScreen> {
  late Timer _countdownTimer;
  Duration _timeUntilEvent = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilEvent();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeUntilEvent();
    });

    // Schedule notifications for this event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EventNotificationScheduler.scheduleEventReminders(
        eventId: widget.event.id,
        eventName: widget.event.title,
        eventStartTime: widget.event.startTime,
        eventLocation: widget.event.location.name,
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _calculateTimeUntilEvent() {
    final now = DateTime.now();
    final eventTime = widget.event.startTime;
    final difference = eventTime.difference(now);

    if (difference.isNegative) {
      _countdownTimer.cancel();
    }

    if (mounted) {
      setState(() {
        _timeUntilEvent = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  String _formatCountdown(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} hari ${duration.inHours % 24} jam';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam ${duration.inMinutes % 60} menit';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit';
    } else {
      return 'Segera!';
    }
  }

  Color _getCountdownColor() {
    final days = _timeUntilEvent.inDays;
    if (days >= 7) return AppColors.textTertiary;
    if (days >= 3) return AppColors.secondary;
    if (days >= 1) return AppColors.warning;
    return AppColors.error;
  }

  TicketStatus _getTicketStatus() {
    if (_timeUntilEvent.inHours < 0) return TicketStatus.completed;
    if (_timeUntilEvent.inHours < 24) return TicketStatus.today;
    return TicketStatus.upcoming;
  }

  String _getTicketStatusText() {
    final status = _getTicketStatus();
    switch (status) {
      case TicketStatus.upcoming:
        return 'AKTIF';
      case TicketStatus.today:
        return 'HARI INI';
      case TicketStatus.completed:
        return 'SELESAI';
    }
  }

  Color _getTicketStatusColor() {
    final status = _getTicketStatus();
    switch (status) {
      case TicketStatus.upcoming:
        return AppColors.secondary;
      case TicketStatus.today:
        return AppColors.warning;
      case TicketStatus.completed:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketId =
        widget.ticketId ??
        'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final status = _getTicketStatus();

    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textEmphasis),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textEmphasis),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Event Header Image
            _buildEventHeader(),
            const SizedBox(height: 20),

            // Event Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 22,
                      color: AppColors.textEmphasis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat(
                          'EEEE, d MMM yyyy • HH:mm',
                        ).format(widget.event.startTime.toLocal()),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.event.location.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Countdown
            _buildCountdown(),

            const SizedBox(height: 20),

            // Ticket Card with QR
            _buildTicketCard(ticketId, status),

            const SizedBox(height: 20),

            // Primary CTA: Cari Temen
            _buildCariTemenButton(),

            const SizedBox(height: 12),

            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.calendar_month_rounded,
                    label: 'Add to Calendar',
                    onTap: _addToCalendar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: _shareEvent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Link to My Tickets
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyTicketsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.confirmation_number_rounded, size: 18),
              label: Text(
                'Lihat Semua Tiket Saya',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: widget.event.fullImageUrls.isNotEmpty
          ? ClipRRect(
              child: CachedNetworkImage(
                imageUrl: widget.event.fullImageUrls.first,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            )
          : const Icon(Icons.event_rounded, size: 64, color: Colors.white24),
    );
  }

  Widget _buildCountdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getCountdownColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCountdownColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: _getCountdownColor()),
          const SizedBox(width: 10),
          Text(
            'Mulai dalam ',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            _formatCountdown(_timeUntilEvent),
            style: AppTextStyles.bodyMediumBold.copyWith(
              color: _getCountdownColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(String ticketId, TicketStatus status) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          // Top section with gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getTicketStatusColor(),
                  _getTicketStatusColor().withValues(alpha: 0.7),
                ],
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
                        _getTicketStatusIcon(),
                        color: AppColors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTicketStatusText(),
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: ticketId,
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: AppColors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.textEmphasis,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.textEmphasis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Scan line animation
                      SizedBox(height: 2, width: 120, child: _buildScanLine()),
                      const SizedBox(height: 8),
                      Text(
                        ticketId,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Tunjukin QR code ini saat check-in',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyTicketId(ticketId),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Kode'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textEmphasis,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveTicketImage,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Simpan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textEmphasis,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanLine() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Align(
          alignment: Alignment(value * 2 - 1, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.secondary.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            height: 2,
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) setState(() {});
      },
    );
  }

  IconData _getTicketStatusIcon() {
    switch (_getTicketStatus()) {
      case TicketStatus.upcoming:
        return Icons.confirmation_number_rounded;
      case TicketStatus.today:
        return Icons.event_available_rounded;
      case TicketStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  Widget _buildCariTemenButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () => _openFindMatches(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_add_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              'Cari Temen Buat Bareng',
              style: AppTextStyles.bodyLargeBold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textEmphasis,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Refresh Tiket'),
              onTap: () {
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Bantuan'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyTicketId(String ticketId) {
    Clipboard.setData(ClipboardData(text: ticketId));
    SnackBarHelper.showInfo(
      context,
      'Kode tiket disalin!',
      duration: const Duration(seconds: 2),
    );
  }

  void _saveTicketImage() {
    SnackBarHelper.showInfo(
      context,
      'Fitur simpan tiket coming soon!',
    );
  }

  void _addToCalendar() {
    SnackBarHelper.showInfo(
      context,
      'Add to Calendar coming soon!',
    );
  }

  void _shareEvent() {
    SnackBarHelper.showInfo(
      context,
      'Share coming soon!',
    );
  }

  void _openFindMatches(BuildContext context) {
    // Open find matches modal or navigate to screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SwipeableEventsScreen()),
    );
  }
}
