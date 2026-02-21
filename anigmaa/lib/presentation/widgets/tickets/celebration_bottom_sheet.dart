import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

class CelebrationBottomSheet extends StatefulWidget {
  final String eventName;
  final String eventId;
  final String? ticketId;
  final VoidCallback onViewTicket;
  final VoidCallback onFindFriends;
  final VoidCallback onShare;

  const CelebrationBottomSheet({
    super.key,
    required this.eventName,
    required this.eventId,
    this.ticketId,
    required this.onViewTicket,
    required this.onFindFriends,
    required this.onShare,
  });

  @override
  State<CelebrationBottomSheet> createState() => _CelebrationBottomSheetState();
}

class _CelebrationBottomSheetState extends State<CelebrationBottomSheet>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _sheetController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  Timer? _autoDismissTimer;
  int _countdown = 5;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
    );

    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            if (mounted) setState(() {});
          });

    _sheetController.forward();
    _fireConfetti();
    _startAutoDismiss();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _sheetController.dispose();
    _progressController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _fireConfetti() {
    _confettiController.play();
  }

  void _startAutoDismiss() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _autoDismissTimer?.cancel();
        if (mounted) {
          Navigator.pop(context);
          widget.onViewTicket();
        }
      }
    });
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _autoDismissTimer?.cancel();
        }
      },
      child: AnimatedBuilder(
        animation: _sheetController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value * 100),
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            _buildContent(context),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                shouldLoop: false,
                colors: const [
                  Color(0xFFBBC863),
                  Color(0xFFFFD700),
                  Color(0xFFFF6B6B),
                  Color(0xFF4ECDC4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Celebration icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 40,
                  color: Color(0xFFBBC863),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Yeay! Kamu resmi ikut!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Tiket kamu sudah siap. Cek sekarang atau cari temen buat bareng!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Event name preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBC863).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        color: Color(0xFFBBC863),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.eventName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Primary CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _autoDismissTimer?.cancel();
                    Navigator.pop(context);
                    widget.onViewTicket();
                  },
                  icon: const Icon(Icons.confirmation_number_rounded, size: 20),
                  label: Text(
                    'Lihat Tiket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBBC863),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary CTAs
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _autoDismissTimer?.cancel();
                        Navigator.pop(context);
                        widget.onFindFriends();
                      },
                      icon: const Icon(Icons.group_add_rounded, size: 18),
                      label: Text(
                        'Cari Temen',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _autoDismissTimer?.cancel();
                        Navigator.pop(context);
                        widget.onShare();
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        'Share',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Auto-dismiss progress bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 1.0 - _progressController.value,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFBBC863),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-close in $_countdown',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textDisabled,
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
}

// Show celebration bottom sheet
Future<T?> showCelebrationBottomSheet<T>({
  required BuildContext context,
  required String eventName,
  required String eventId,
  String? ticketId,
  required VoidCallback onViewTicket,
  required VoidCallback onFindFriends,
  required VoidCallback onShare,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    enableDrag: false,
    builder: (context) => CelebrationBottomSheet(
      eventName: eventName,
      eventId: eventId,
      ticketId: ticketId,
      onViewTicket: onViewTicket,
      onFindFriends: onFindFriends,
      onShare: onShare,
    ),
  );
}
