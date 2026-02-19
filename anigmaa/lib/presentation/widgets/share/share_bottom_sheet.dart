import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/post.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ShareBottomSheet extends StatelessWidget {
  final Post post;

  const ShareBottomSheet({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share Post',
              style: AppTextStyles.bodyLargeBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Preview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.cardSurface,
                    child: Text(
                      post.author.name.isNotEmpty
                          ? post.author.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.name,
                          style: AppTextStyles.bodyMediumBold,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          post.content.length > 50
                              ? '${post.content.substring(0, 50)}...'
                              : post.content,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Share options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 20,
                crossAxisSpacing: 10,
                childAspectRatio: 0.7,
                children: [
                  _buildShareOption(
                    icon: Icons.link,
                    label: 'Copy Link',
                    color: AppColors.textSecondary,
                    onTap: () {
                      _copyPostLink(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.message,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      _shareToWhatsApp(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () {
                      _shareToFacebook(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.alternate_email,
                    label: 'Twitter',
                    color: Colors.lightBlue,
                    onTap: () {
                      _shareToTwitter(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.camera_alt,
                    label: 'Instagram',
                    color: Colors.purple,
                    onTap: () {
                      _shareToInstagram(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.email,
                    label: 'Email',
                    color: AppColors.error,
                    onTap: () {
                      _shareViaEmail(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.share,
                    label: 'More',
                    color: AppColors.textSecondary,
                    onTap: () {
                      _shareMore(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.qr_code,
                    label: 'QR Code',
                    color: AppColors.primary,
                    onTap: () {
                      _showQRCode(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _copyPostLink(BuildContext context) {
    // TODO: Generate actual post link
    final postLink = 'https://anigmaa.app/post/${post.id}';

    Clipboard.setData(ClipboardData(text: postLink)).then((_) {
      Navigator.pop(context);
      _showShareMessage(context, 'Link copied to clipboard!');
    });
  }

  void _shareToWhatsApp(BuildContext context) {
    Navigator.pop(context);
    final message = 'Check out this post: ${post.content}';
    _launchURL('https://wa.me/?text=${Uri.encodeComponent(message)}');
  }

  void _shareToFacebook(BuildContext context) {
    Navigator.pop(context);
    _showShareMessage(context, 'Facebook sharing coming soon!');
  }

  void _shareToTwitter(BuildContext context) {
    Navigator.pop(context);
    final message = 'Check out this post: ${post.content}';
    _launchURL('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(message)}');
  }

  void _shareToInstagram(BuildContext context) {
    Navigator.pop(context);
    _showShareMessage(context, 'Instagram sharing not available');
  }

  void _shareViaEmail(BuildContext context) {
    Navigator.pop(context);
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Check out this post',
        'body': 'Check out this post: ${post.content}',
      },
    );
    _launchURL(uri.toString());
  }

  void _shareMore(BuildContext context) {
    Navigator.pop(context);
    _showShareMessage(context, 'Native sharing coming soon!');
  }

  void _showQRCode(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implement QR code display
    _showShareMessage(context, 'QR Code feature coming soon!');
  }

  void _showShareMessage(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(platform),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}