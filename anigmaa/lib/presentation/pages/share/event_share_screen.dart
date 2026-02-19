// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class EventShareScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String eventDate;
  final String? eventLocation;
  final String? eventImage;
  final String? eventDescription;
  final double? price;

  const EventShareScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    this.eventLocation,
    this.eventImage,
    this.eventDescription,
    this.price,
  });

  @override
  State<EventShareScreen> createState() => _EventShareScreenState();
}

class _EventShareScreenState extends State<EventShareScreen> {
  late String _shareLink;

  @override
  void initState() {
    super.initState();
    _shareLink = 'https://flyerr.id/event/${widget.eventId}';
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(),
                    const SizedBox(height: 24),
                    _buildShareLinkSection(),
                    const SizedBox(height: 24),
                    _buildSocialShareButtons(),
                    const SizedBox(height: 24),
                    _buildShareStats(),
                  ],
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
      decoration: BoxDecoration(
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
              'Bagikan Event',
              style: AppTextStyles.bodyLargeBold.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Kartu',
          style: AppTextStyles.bodyMediumBold.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          LucideIcons.calendar,
                          size: 48,
                          color: AppColors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      // Logo watermark
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Flyerr',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventName,
                      style: AppTextStyles.bodyLargeBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.eventDate,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.eventLocation != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.eventLocation!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.price != null && widget.price! > 0)
                          Text(
                            'Rp ${_formatAmount(widget.price!)}',
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 18,
                              color: AppColors.secondary,
                            ),
                          )
                        else
                          Text(
                            'Gratis',
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 18,
                              color: AppColors.secondary,
                            ),
                          ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            minimumSize: const Size(80, 32),
                          ),
                          child: Text(
                            'Join',
                            style: AppTextStyles.bodySmall,
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
      ],
    );
  }

  Widget _buildShareLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Link Event',
          style: AppTextStyles.bodyMediumBold.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    _shareLink,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 18),
                onPressed: _copyLink,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.shield, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              'Link akan aktif selama event tersedia',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialShareButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bagikan ke',
          style: AppTextStyles.bodyMediumBold.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSocialButton(
              LucideIcons.messageCircle,
              'WhatsApp',
              const Color(0xFF25D366),
              _shareToWhatsApp,
            ),
            _buildSocialButton(
              LucideIcons.send,
              'Telegram',
              const Color(0xFF0088cc),
              _shareToTelegram,
            ),
            _buildSocialButton(
              LucideIcons.mail,
              'Email',
              const Color(0xFFEA4335),
              _shareToEmail,
            ),
            _buildSocialButton(
              LucideIcons.moreHorizontal,
              'Lainnya',
              AppColors.textSecondary,
              _shareMore,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildShareStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart2, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Statistik Bagikan',
                style: AppTextStyles.bodyMediumBold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('123', 'Dilihat'),
              _buildStatItem('45', 'Diklik'),
              _buildStatItem('12', 'Bergabung'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            fontSize: 20,
            color: AppColors.secondary,
          ),
        ),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _shareLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: AppColors.white),
            SizedBox(width: 12),
            Text('Link berhasil disalin!'),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareToWhatsApp() {
    // TODO: Implement WhatsApp sharing
    _showShareSuccess('WhatsApp');
  }

  void _shareToTelegram() {
    // TODO: Implement Telegram sharing
    _showShareSuccess('Telegram');
  }

  void _shareToEmail() {
    // TODO: Implement email sharing
    _showShareSuccess('Email');
  }

  void _shareMore() {
    // TODO: Implement native share sheet
    _showShareSuccess('Native Share');
  }

  void _showShareSuccess(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka $platform...'),
        duration: const Duration(seconds: 2),
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
