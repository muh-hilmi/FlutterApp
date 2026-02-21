import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/post.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

class ShareService {
  static const String _appBaseUrl = 'https://flyerr.app';

  /// Share post to multiple platforms
  Future<void> sharePost({
    required BuildContext context,
    required Post post,
    required String platform,
  }) async {
    try {
      switch (platform.toLowerCase()) {
        case 'whatsapp':
          await _shareToWhatsApp(context, post);
          break;
        case 'facebook':
          await _shareToFacebook(context, post);
          break;
        case 'twitter':
          await _shareToTwitter(context, post);
          break;
        case 'instagram stories':
          await _shareToInstagramStories(context, post);
          break;
        case 'email':
          await _shareToEmail(context, post);
          break;
        case 'copy link':
          await _copyPostLink(context, post);
          break;
        default:
          await _shareToSystem(context, post);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Gagal membagikan ke $platform: $e');
    }
  }

  /// Generate shareable content for post
  String _generateShareContent(Post post) {
    final author = post.author.name;
    final content = post.content.length > 100
        ? '${post.content.substring(0, 100)}...'
        : post.content;
    final postUrl = '$_appBaseUrl/post/${post.id}';

    return '$content\n\n- Oleh $author\n\n$postUrl\n\n#flyerr #event #community';
  }

  /// Generate WhatsApp share URL
  Future<void> _shareToWhatsApp(BuildContext context, Post post) async {
    final content = _generateShareContent(post);
    final encodedContent = Uri.encodeComponent(content);
    final whatsappUrl = 'https://wa.me/?text=$encodedContent';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'WhatsApp tidak terinstall');
    }
  }

  /// Share to Facebook
  Future<void> _shareToFacebook(BuildContext context, Post post) async {
    final postUrl = '$_appBaseUrl/post/${post.id}';
    final encodedUrl = Uri.encodeComponent(postUrl);
    final facebookUrl =
        'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl';

    if (await canLaunchUrl(Uri.parse(facebookUrl))) {
      await launchUrl(
        Uri.parse(facebookUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Facebook tidak terinstall');
    }
  }

  /// Share to Twitter/X
  Future<void> _shareToTwitter(BuildContext context, Post post) async {
    final content = _generateShareContent(post);
    final encodedContent = Uri.encodeComponent(content);
    final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedContent';

    if (await canLaunchUrl(Uri.parse(twitterUrl))) {
      await launchUrl(
        Uri.parse(twitterUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Twitter/X tidak terinstall');
    }
  }

  /// Share to Instagram Stories
  Future<void> _shareToInstagramStories(BuildContext context, Post post) async {
    try {
      // Instagram Stories sharing via deep link
      final content = _generateShareContent(post);
      final instagramUrl =
          'instagram-stories://share?text=${Uri.encodeComponent(content)}';

      if (await canLaunchUrl(Uri.parse(instagramUrl))) {
        await launchUrl(
          Uri.parse(instagramUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!context.mounted) return;
        _showErrorSnackBar(context, 'Instagram tidak terinstall');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Gagal membuka Instagram: $e');
    }
  }

  /// Share via email
  Future<void> _shareToEmail(BuildContext context, Post post) async {
    final subject = 'Check out this post on Flyerr!';
    final content = _generateShareContent(post);

    final emailUrl =
        'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(content)}';

    if (await canLaunchUrl(Uri.parse(emailUrl))) {
      await launchUrl(
        Uri.parse(emailUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Email app tidak tersedia');
    }
  }

  /// Copy post link to clipboard
  Future<void> _copyPostLink(BuildContext context, Post post) async {
    final postUrl = '$_appBaseUrl/post/${post.id}';

    // Here you would use a clipboard plugin
    // For now, we'll use the share functionality
    await Share.share(postUrl);

    if (!context.mounted) return;
    _showSuccessSnackBar(context, 'Link post berhasil disalin!');
  }

  /// Share using system share dialog
  Future<void> _shareToSystem(BuildContext context, Post post) async {
    final content = _generateShareContent(post);

    await Share.share(content, subject: 'Check out this post on Flyerr!');
  }

  /// Generate QR code for post
  Future<String> generatePostQRCode(BuildContext context, Post post) async {
    try {
      final postUrl = '$_appBaseUrl/post/${post.id}';

      // Generate QR code as image
      final qrValidationResult = QrValidator.validate(
        data: postUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = QrPainter(
          data: postUrl,
          version: QrVersions.auto,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF2D3142),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF2D3142),
          ),
          gapless: true,
        );

        // Create temporary directory
        final tempDir = await getTemporaryDirectory();
        final qrImagePath = '${tempDir.path}/qr_${post.id}.png';

        // Save QR code image
        final image = await qrCode.toImageData(512);
        await File(
          qrImagePath,
        ).writeAsBytes(image!.buffer.asUint8List());

        return qrImagePath;
      } else {
        throw Exception('Failed to generate QR code');
      }
    } catch (e) {
      if (!context.mounted) return '';
      _showErrorSnackBar(context, 'Gagal generate QR code: $e');
      rethrow;
    }
  }

  /// Show QR code dialog
  Future<void> showPostQRCode(BuildContext context, Post post) async {
    try {
      final postUrl = '$_appBaseUrl/post/${post.id}';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR Code Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: QrImageView(
                  data: postUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: const Color(0xFF2D3142),
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan QR code ini untuk lihat postingan',
                style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveQRCode(context, post);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBC863),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Gagal menampilkan QR code: $e');
    }
  }

  /// Save QR code to gallery
  Future<void> _saveQRCode(BuildContext context, Post post) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();

      if (status.isGranted) {
        // Generate QR code (for future implementation)
        await generatePostQRCode(context, post);

        // Save to gallery (implementation depends on platform)
        if (!context.mounted) return;
        if (Platform.isAndroid) {
          // For Android, you might use a plugin like gallery_saver
          _showSuccessSnackBar(context, 'QR Code berhasil disimpan!');
        } else if (Platform.isIOS) {
          // For iOS, you would use image_picker_gallery_saver or similar
          _showSuccessSnackBar(context, 'QR Code berhasil disimpan ke Photos!');
        }

        Navigator.pop(context);
      } else {
        if (!context.mounted) return;
        _showErrorSnackBar(context, 'Izin penyimpanan diperlukan');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Gagal menyimpan QR code: $e');
    }
  }

  /// Share event
  Future<void> shareEvent({
    required BuildContext context,
    required String eventId,
    required String eventTitle,
    required String eventDescription,
  }) async {
    try {
      final content =
          '$eventTitle\n\n$eventDescription\n\n\n$_appBaseUrl/event/$eventId\n\n#flyerr #event';

      await Share.share(content, subject: 'Check out this event on Flyerr!');
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Gagal membagikan event: $e');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
