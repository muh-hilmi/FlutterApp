// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum ReportType {
  harassment,
  spam,
  falseInformation,
  inappropriate,
  violence,
  copyright,
  other,
}

enum ReportTargetType { user, event, post, community, comment }

class ReportScreen extends StatefulWidget {
  final String? targetId;
  final ReportTargetType targetType;
  final String? targetName;

  const ReportScreen({
    super.key,
    this.targetId,
    required this.targetType,
    this.targetName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportType? _selectedReason;
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final Map<ReportType, ReportReason> _reasons = {
    ReportType.harassment: ReportReason(
      'Pelecehan',
      'Bully, threats, atau pelecehan verbal',
      LucideIcons.userX,
    ),
    ReportType.spam: ReportReason(
      'Spam',
      'Konten berulang atau tidak relevan',
      LucideIcons.ban,
    ),
    ReportType.falseInformation: ReportReason(
      'Informasi Salah',
      'Berita palsu atau informasi menyesatkan',
      LucideIcons.alertOctagon,
    ),
    ReportType.inappropriate: ReportReason(
      'Konten Tidak Pantas',
      'Konten dewasa atau vulgar',
      LucideIcons.eyeOff,
    ),
    ReportType.violence: ReportReason(
      'Kekerasan',
      'Konten kekerasan atau berbahaya',
      LucideIcons.sword,
    ),
    ReportType.copyright: ReportReason(
      'Pelanggaran Hak Cipta',
      'Menggunakan konten tanpa izin',
      LucideIcons.copyright,
    ),
    ReportType.other: ReportReason(
      'Lainnya',
      'Alasan lain yang tidak tercantum',
      LucideIcons.moreHorizontal,
    ),
  };

  @override
  void dispose() {
    _descriptionController.dispose();
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTargetInfo(),
                      const SizedBox(height: 24),
                      _buildReasonSection(),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      _buildWarningSection(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
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
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Laporkan',
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

  Widget _buildTargetInfo() {
    String targetLabel = _getTargetLabel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.flag, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Melaporkan',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
                Text(
                  widget.targetName ?? targetLabel,
                  style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alasan Laporan',
          style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih alasan mengapa kamu melaporkan konten ini',
          style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...ReportType.values.map((type) {
          return _buildReasonOption(_reasons[type]!, type);
        }),
      ],
    );
  }

  Widget _buildReasonOption(ReportReason reason, ReportType type) {
    final isSelected = _selectedReason == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.05)
              : AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                reason.icon,
                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.secondary : AppColors.textEmphasis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason.description,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.secondary : AppColors.textTertiary,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        LucideIcons.check,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi Tambahan (Opsional)',
          style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Berikan detail tambahan untuk membantu kami meninjau laporan ini',
          style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Jelaskan lebih lanjut...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
            filled: true,
            fillColor: AppColors.surfaceAlt,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEAA7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldAlert, size: 20, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privasi Terlindungi',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Identitas pelapor akan dirahasiakan. Pengguna yang dilaporkan tidak akan mengetahui siapa yang melaporkan.',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.orange[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedReason == null || _isSubmitting
            ? null
            : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          disabledBackgroundColor: AppColors.border,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                'Kirim Laporan',
                style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.white),
              ),
      ),
    );
  }

  void _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
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
                color: Color(0xFFD4EDDA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                size: 32,
                color: Color(0xFF155724),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Laporan Terkirim',
              style: AppTextStyles.bodyLargeBold.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terima kasih telah membantu kami menjaga komunitas tetap aman.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Selesai', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTargetLabel() {
    switch (widget.targetType) {
      case ReportTargetType.user:
        return 'Pengguna';
      case ReportTargetType.event:
        return 'Event';
      case ReportTargetType.post:
        return 'Postingan';
      case ReportTargetType.community:
        return 'Komunitas';
      case ReportTargetType.comment:
        return 'Komentar';
    }
  }
}

class ReportReason {
  final String title;
  final String description;
  final IconData icon;

  ReportReason(this.title, this.description, this.icon);
}
