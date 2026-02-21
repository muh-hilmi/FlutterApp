import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection_container.dart' as di;
import '../../bloc/event_participants/event_participants_bloc.dart';
import '../../bloc/event_participants/event_participants_state.dart';

enum _Mode { scan, manual }

class QRCheckinScreen extends StatefulWidget {
  final String eventId;

  const QRCheckinScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<QRCheckinScreen> createState() => _QRCheckinScreenState();
}

class _QRCheckinScreenState extends State<QRCheckinScreen>
    with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _Mode _mode = _Mode.manual;

  // Scan line animation
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  // Banner animation
  late AnimationController _bannerCtrl;
  late Animation<Offset> _bannerSlide;
  String _bannerMsg = '';
  bool _bannerSuccess = true;

  @override
  void initState() {
    super.initState();

    _scanLineCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _scanLineAnim = CurvedAnimation(
      parent: _scanLineCtrl,
      curve: Curves.easeInOut,
    );

    _bannerCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOutCubic));

    _codeController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _scanLineCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  void _showBanner(String msg, {bool success = true}) {
    setState(() {
      _bannerMsg = msg;
      _bannerSuccess = success;
    });
    _bannerCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _bannerCtrl.reverse();
    });
  }

  void _handleCheckIn(BuildContext context) {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) return;

    // TODO: dispatch CheckInAttendee event to BLoC
    // context.read<EventParticipantsBloc>().add(CheckInByCode(widget.eventId, code));

    // Placeholder until wired
    _showPlaceholderDialog(context, code);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<EventParticipantsBloc>(),
      child: Scaffold(
        key: const Key('qr_checkin_screen'),
        backgroundColor: AppColors.primary,
        body: BlocListener<EventParticipantsBloc, EventParticipantsState>(
          listener: (context, state) {
            if (state is EventAttendeeCheckedIn) {
              _showBanner('${state.attendee.name} berhasil check-in! ✓', success: true);
              _codeController.clear();
              if (_mode == _Mode.manual) _focusNode.requestFocus();
            } else if (state is EventParticipantsError) {
              _showBanner(state.message, success: false);
              _codeController.clear();
              if (_mode == _Mode.manual) _focusNode.requestFocus();
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  _buildDarkHeader(),
                  _buildWhiteBody(),
                ],
              ),
              _buildFloatingBanner(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Dark Header ────────────────────────────────────────────────────────────

  Widget _buildDarkHeader() {
    return BlocBuilder<EventParticipantsBloc, EventParticipantsState>(
      builder: (context, state) {
        final checkedIn =
            state is EventParticipantsLoaded ? state.checkedInCount : 0;
        final total =
            state is EventParticipantsLoaded ? state.attendees.length : 0;
        final progress = total > 0 ? checkedIn / total : 0.0;

        return Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Check-In Peserta',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      // LIVE badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'LIVE',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.secondary,
                                letterSpacing: 1.2,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Stats
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Big number
                      Text(
                        '$checkedIn',
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.secondary,
                          fontSize: 64,
                          letterSpacing: -2.5,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 6),
                        child: Text(
                          '/ $total',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white.withValues(alpha: 0.4),
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'sudah check-in',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.white.withValues(alpha: 0.5),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            total > 0
                                ? '${(progress * 100).toStringAsFixed(0)}%'
                                : '—',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondary,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      key: const Key('checkin_stats_section'),
                      value: progress,
                      backgroundColor: AppColors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Tiket terjual',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$total tiket',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── White Body ─────────────────────────────────────────────────────────────

  Widget _buildWhiteBody() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildModeToggle(),
            ),
            Expanded(
              child: _mode == _Mode.scan ? _buildScanMode() : _buildManualMode(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mode Toggle ────────────────────────────────────────────────────────────

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildModeTab(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
            mode: _Mode.scan,
          ),
          _buildModeTab(
            icon: Icons.keyboard_rounded,
            label: 'Kode Manual',
            mode: _Mode.manual,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required _Mode mode,
  }) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_mode == mode) return;
          setState(() => _mode = mode);
          if (mode == _Mode.manual) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) _focusNode.requestFocus();
            });
          } else {
            _focusNode.unfocus();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isActive ? AppColors.secondary : AppColors.textTertiary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: isActive ? AppColors.white : AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Scan Mode ─────────────────────────────────────────────────────────────

  Widget _buildScanMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          // QR scanner area
          Container(
            key: const Key('qr_scanner_placeholder'),
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Corner brackets
                ..._buildCornerBrackets(),

                // Scan line
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (context, _) {
                    return Positioned(
                      top: 44 + (_scanLineAnim.value * 172),
                      left: 44,
                      right: 44,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withValues(alpha: 0),
                              AppColors.secondary.withValues(alpha: 0.9),
                              AppColors.secondary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Center placeholder content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_rounded,
                        size: 60,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Kamera segera hadir',
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gunakan kode manual dulu ya',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Switch to manual CTA
          GestureDetector(
            onTap: () => setState(() => _mode = _Mode.manual),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.keyboard_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Input kode manual',
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const c = AppColors.secondary;
    const t = 3.0;
    const s = 30.0;
    const m = 22.0;
    return [
      Positioned(
        top: m,
        left: m,
        child: _Bracket(size: s, thickness: t, color: c, top: true, left: true),
      ),
      Positioned(
        top: m,
        right: m,
        child: _Bracket(size: s, thickness: t, color: c, top: true, left: false),
      ),
      Positioned(
        bottom: m,
        left: m,
        child: _Bracket(size: s, thickness: t, color: c, top: false, left: true),
      ),
      Positioned(
        bottom: m,
        right: m,
        child: _Bracket(size: s, thickness: t, color: c, top: false, left: false),
      ),
    ];
  }

  // ─── Manual Mode ────────────────────────────────────────────────────────────

  Widget _buildManualMode() {
    return BlocBuilder<EventParticipantsBloc, EventParticipantsState>(
      builder: (context, state) {
        final isLoading = state is EventParticipantsLoading;
        final code = _codeController.text.toUpperCase();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kode Kehadiran',
                style: AppTextStyles.bodyLargeBold,
              ),
              const SizedBox(height: 4),
              Text(
                'Ketik 8-digit kode dari tiket peserta',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),

              // OTP boxes + hidden text field
              Stack(
                children: [
                  // OTP visual boxes
                  GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(8, (i) {
                        final char = i < code.length ? code[i] : '';
                        final isCursor = i == code.length && _focusNode.hasFocus;
                        return _buildCodeBox(char, isCursor, i < 4);
                      }),
                    ),
                  ),

                  // Invisible text field overlaid to capture keyboard input
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.0,
                      child: TextField(
                        key: const Key('attendance_code_input'),
                        controller: _codeController,
                        focusNode: _focusNode,
                        maxLength: 8,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (value.length == 8) _handleCheckIn(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Character counter
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${code.length} / 8',
                    style: AppTextStyles.captionSmall.copyWith(
                      color: code.length == 8
                          ? AppColors.secondary
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Check-in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('manual_checkin_button'),
                  onPressed: (code.length == 8 && !isLoading)
                      ? () => _handleCheckIn(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.surfaceAlt,
                    disabledForegroundColor: AppColors.textDisabled,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.how_to_reg_rounded,
                              size: 20,
                              color: code.length == 8
                                  ? AppColors.secondary
                                  : AppColors.textDisabled,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Check-In Peserta',
                              style: AppTextStyles.button.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),

              // Clear button
              if (code.isNotEmpty) ...[
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      _codeController.clear();
                      setState(() {});
                      _focusNode.requestFocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Hapus kode',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Tip card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kode otomatis submit saat 8 karakter sudah diisi.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodeBox(String char, bool isCursor, bool isFirstGroup) {
    final filled = char.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 36,
      height: 52,
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isCursor
              ? AppColors.secondary
              : filled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
          width: isCursor ? 2.5 : 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (filled)
            Text(
              char,
              style: AppTextStyles.h3.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
          // Cursor blink indicator
          if (isCursor && !filled)
            Container(
              width: 2,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Floating Banner ────────────────────────────────────────────────────────

  Widget _buildFloatingBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _bannerSlide,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _bannerSuccess ? AppColors.success : AppColors.orange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_bannerSuccess ? AppColors.success : AppColors.orange)
                        .withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _bannerSuccess
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _bannerMsg,
                      style: AppTextStyles.bodyMediumBold.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Placeholder Dialog (until BLoC is wired) ───────────────────────────────

  void _showPlaceholderDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: AppColors.secondary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'API Belum Terhubung',
                style: AppTextStyles.h3.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Kode: $code',
                style: AppTextStyles.bodyLargeBold.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Check-in via kode belum di-wire ke BLoC. Gunakan scanner QR saat API sudah siap.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _codeController.clear();
                    _focusNode.requestFocus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text('OK', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Corner Bracket Painter ──────────────────────────────────────────────────

class _Bracket extends StatelessWidget {
  final double size;
  final double thickness;
  final Color color;
  final bool top;
  final bool left;

  const _Bracket({
    required this.size,
    required this.thickness,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BracketPainter(
          color: color,
          thickness: thickness,
          top: top,
          left: left,
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  const _BracketPainter({
    required this.color,
    required this.thickness,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color || old.thickness != thickness;
}
