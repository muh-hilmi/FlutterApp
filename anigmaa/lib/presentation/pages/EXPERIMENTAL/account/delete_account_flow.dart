// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/datasources/user_remote_datasource.dart';
import '../../../injection_container.dart' as di;
import '../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum DeletionReason {
  notUsingAnymore,
  privacyConcerns,
  tooManyNotifications,
  foundAlternative,
  technicalIssues,
  dataConcerns,
  expensive,
  other,
}

class DeleteAccountFlow extends StatefulWidget {
  const DeleteAccountFlow({super.key});

  @override
  State<DeleteAccountFlow> createState() => _DeleteAccountFlowState();
}

class _DeleteAccountFlowState extends State<DeleteAccountFlow> {
  int _currentStep = 1;
  DeletionReason? _selectedReason;
  final _reasonController = TextEditingController();
  bool _understandConsequences = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    const SizedBox(height: 24),
                    if (_currentStep == 1) _buildStep1Info(),
                    if (_currentStep == 2) _buildStep2Reason(),
                    if (_currentStep == 3) _buildStep3Confirmation(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () {
                setState(() {
                  if (_currentStep > 1) _currentStep--;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: Text(
              'Hapus Akun',
              style: AppTextStyles.bodyLargeBold.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepDot(1, 'Info'),
        _buildStepLine(1),
        _buildStepDot(2, 'Alasan'),
        _buildStepLine(2),
        _buildStepDot(3, 'Konfirmasi'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.error : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int from) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        color: _currentStep > from ? AppColors.error : AppColors.border,
      ),
    );
  }

  Widget _buildStep1Info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
        const SizedBox(height: 20),
        Text(
          'Hapus Akun Anda?',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Text(
          'Tindakan ini tidak dapat dibatalkan. Berikut yang akan terjadi:',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _buildConsequenceItem(
          LucideIcons.userX,
          'Profil & Data Pribadi',
          'Semua data pribadi Anda akan dihapus permanen.',
        ),
        _buildConsequenceItem(
          LucideIcons.calendarX,
          'Event & Tiket',
          'Tiket yang Anda beli akan tidak dapat diakses.',
        ),
        _buildConsequenceItem(
          LucideIcons.messageSquare,
          'Postingan & Komentar',
          'Konten yang Anda buat akan dihapus atau anonim.',
        ),
        _buildConsequenceItem(
          LucideIcons.users,
          'Komunitas',
          'Anda akan keluar dari semua komunitas yang diikuti.',
        ),
        _buildConsequenceItem(
          LucideIcons.history,
          'Riwayat Transaksi',
          'Data transaksi akan dihapus sesuai kebijakan retensi.',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 18, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Menurut kebijakan GDPR, Anda berhak meminta penghapusan data pribadi Anda.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Reason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mengapa Anda ingin pergi?',
          style: AppTextStyles.bodyLargeBold.copyWith(
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bantu kami meningkatkan layanan dengan memberitahu alasan Anda.',
          style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        ...DeletionReason.values.map((reason) {
          return _buildReasonOption(reason);
        }),
        if (_selectedReason == DeletionReason.other) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Jelaskan alasan Anda...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildAlternativeCard(),
      ],
    );
  }

  Widget _buildStep3Confirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.shieldAlert, size: 48, color: AppColors.error),
        const SizedBox(height: 20),
        Text(
          'Konfirmasi Penghapusan',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Peringatan Terakhir',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Anda akan kehilangan akses permanen ke akun dan semua data yang terkait. Tindakan ini tidak dapat dibatalkan.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildConfirmationCheckbox(),
      ],
    );
  }

  Widget _buildConfirmationCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _understandConsequences,
                onChanged: (value) {
                  setState(() {
                    _understandConsequences = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _understandConsequences = !_understandConsequences;
                    });
                  },
                  child: Text(
                    'Saya memahami bahwa tindakan ini tidak dapat dibatalkan dan semua data saya akan dihapus permanen.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsequenceItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textEmphasis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOption(DeletionReason reason) {
    final isSelected = _selectedReason == reason;
    final labels = {
      DeletionReason.notUsingAnymore: 'Tidak menggunakan lagi',
      DeletionReason.privacyConcerns: 'Kekhawatiran privasi',
      DeletionReason.tooManyNotifications: 'Terlalu banyak notifikasi',
      DeletionReason.foundAlternative: 'Menemukan alternatif lain',
      DeletionReason.technicalIssues: 'Masalah teknis',
      DeletionReason.dataConcerns: 'Kekhawatiran data',
      DeletionReason.expensive: 'Terlalu mahal',
      DeletionReason.other: 'Lainnya',
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.error.withValues(alpha: 0.05) : AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.error : AppColors.textTertiary,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        LucideIcons.check,
                        size: 14,
                        color: AppColors.error,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              labels[reason] ?? reason.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.error : AppColors.textEmphasis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Pertimbangkan Alternatif',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Alih-alih menghapus akun, Anda bisa:',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: 8),
          _buildAlternativeItem('Nonaktifkan notifikasi di pengaturan'),
          _buildAlternativeItem('Logout sementara dari akun'),
          _buildAlternativeItem('Ubah pengaturan privasi'),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(LucideIcons.settings, size: 16),
            label: const Text('Ke Pengaturan'),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 12, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    String buttonText;
    VoidCallback? onPressed;
    const Color buttonColor = AppColors.error;

    switch (_currentStep) {
      case 1:
        buttonText = 'Lanjut';
        onPressed = () {
          setState(() {
            _currentStep = 2;
          });
        };
        break;
      case 2:
        buttonText = 'Lanjut';
        onPressed = _selectedReason != null
            ? () {
                setState(() {
                  _currentStep = 3;
                });
              }
            : null;
        break;
      case 3:
        buttonText = 'Hapus Akun Saya';
        onPressed = (_understandConsequences && !_isDeleting) ? _deleteAccount : null;
        break;
      default:
        buttonText = 'Lanjut';
        onPressed = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Text(
                    buttonText,
                    style: AppTextStyles.bodyLargeBold,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Call actual backend API to delete account
      final userDataSource = di.sl<UserRemoteDataSource>();
      await userDataSource.deleteAccount();

      // Clear local auth data
      final authService = di.sl<AuthService>();
      await authService.clearAuthData();

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        _showDeletionComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus akun: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeletionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.userX,
                size: 32,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Akun Berhasil Dihapus',
              style: AppTextStyles.bodyLargeBold.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Akun Anda telah dihapus secara permanen. Sampai jumpa!',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to login and clear all routes
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Kembali ke Login', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
