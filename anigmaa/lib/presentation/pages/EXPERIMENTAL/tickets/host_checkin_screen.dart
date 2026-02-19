import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/tickets/tickets_bloc.dart';
import '../../../bloc/tickets/tickets_event.dart';
import '../../../bloc/tickets/tickets_state.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HostCheckInScreen extends StatefulWidget {
  final String eventId;

  const HostCheckInScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<HostCheckInScreen> createState() => _HostCheckInScreenState();
}

class _HostCheckInScreenState extends State<HostCheckInScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _checkedInCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Load initial stats
      context.read<TicketsBloc>().add(LoadEventTickets(widget.eventId));
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<TicketsBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.cardSurface,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text(
            'Check-In Peserta',
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
        body: BlocListener<TicketsBloc, TicketsState>(
          listener: (context, state) {
            if (state is TicketCheckedIn) {
              _showCheckInSuccess(context, state.ticket.attendanceCode);
              _codeController.clear();
              _focusNode.requestFocus();
              // Refresh stats after successful check-in
              context.read<TicketsBloc>().add(LoadEventTickets(widget.eventId));
            } else if (state is EventTicketsLoaded) {
              setState(() {
                _checkedInCount = state.checkedInCount;
                _totalCount = state.totalCount;
              });
            } else if (state is TicketsError) {
              _showError(context, state.message);
              _codeController.clear();
              _focusNode.requestFocus();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions card
                Container(
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
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Cara Check-In',
                            style: AppTextStyles.bodyLargeBold.copyWith(
                              fontSize: 17,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Minta peserta tunjukin kode kehadiran\n'
                        '2. Masukin kode 4 karakter di bawah\n'
                        '3. Klik "Check-In" buat verifikasi',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.info,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Code input section
                Text(
                  'Masukin Kode Kehadiran',
                  style: AppTextStyles.bodyLargeBold.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Code input field
                      TextField(
                        controller: _codeController,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 8,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                          color: AppColors.secondary,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'XXXXXXXX',
                          hintStyle: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 12,
                            color: AppColors.border,
                            fontFamily: 'monospace',
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.secondary,
                              width: 3,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.cardSurface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 8) {
                            // Auto check-in when 8 characters entered
                            _handleCheckIn(context);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      // Check-in button
                      BlocBuilder<TicketsBloc, TicketsState>(
                        builder: (context, state) {
                          final isLoading = state is TicketsLoading;

                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_codeController.text.length == 8 && !isLoading)
                                  ? () => _handleCheckIn(context)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.white,
                                disabledBackgroundColor: AppColors.border,
                                disabledForegroundColor: AppColors.textTertiary,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Check-In Peserta',
                                      style: AppTextStyles.button.copyWith(
                                        fontSize: 17,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Stats section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik Check-In',
                        style: AppTextStyles.bodyLargeBold,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.check_circle,
                              label: 'Udah Check-In',
                              value: '$_checkedInCount',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.people,
                              label: 'Total Tiket',
                              value: '$_totalCount',
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleCheckIn(BuildContext context) {
    final code = _codeController.text.trim().toUpperCase();

    if (code.length != 8) {
      _showError(context, 'Masukin kode 8 karakter yang bener ya');
      return;
    }

    // Dispatch check-in event with eventId for host flow
    context.read<TicketsBloc>().add(
          CheckInTicketRequested(
            attendanceCode: code,
            eventId: widget.eventId,
          ),
        );
  }

  void _showCheckInSuccess(BuildContext context, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Check-In Berhasil!',
                style: AppTextStyles.h2.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tiket $code udah diverifikasi nih',
                style: AppTextStyles.button.copyWith(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lanjut',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Waduh, Check-In Gagal',
                style: AppTextStyles.h2.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTextStyles.button.copyWith(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
