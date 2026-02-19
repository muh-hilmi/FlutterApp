import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum NetworkStatus { online, offline, connecting }

class NetworkErrorWidget extends StatelessWidget {
  final NetworkStatus status;
  final VoidCallback? onRetry;
  final bool showBanner;
  final Widget? child;

  const NetworkErrorWidget({
    super.key,
    required this.status,
    this.onRetry,
    this.showBanner = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (showBanner) {
      return _buildWithBanner(context);
    }

    return _buildFullPage(context);
  }

  Widget _buildWithBanner(BuildContext context) {
    if (status == NetworkStatus.online && child != null) {
      return child!;
    }

    return Column(
      children: [
        _buildOfflineBanner(),
        Expanded(child: child ?? const SizedBox()),
      ],
    );
  }

  Widget _buildFullPage(BuildContext context) {
    IconData icon;
    String title;
    String message;
    Color iconColor;

    switch (status) {
      case NetworkStatus.offline:
        icon = LucideIcons.wifiOff;
        title = 'Tidak Ada Koneksi';
        message = 'Periksa koneksi internet Anda dan coba lagi.';
        iconColor = Colors.orange;
        break;
      case NetworkStatus.connecting:
        icon = LucideIcons.loader;
        title = 'Menghubungkan...';
        message = 'Mencoba menghubungkan kembali ke server.';
        iconColor = AppColors.secondary;
        break;
      case NetworkStatus.online:
        icon = LucideIcons.wifi;
        title = 'Koneksi Kembali';
        message = 'Internet Anda telah terhubung kembali.';
        iconColor = AppColors.secondary;
        break;
    }

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Elements
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(child: Icon(icon, size: 50, color: iconColor)),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  message,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (status == NetworkStatus.offline) ...[
                  const SizedBox(height: 32),
                  _buildRetryButton(),
                  const SizedBox(height: 24),
                  _buildOfflineTips(),
                ],
                if (status == NetworkStatus.connecting) ...[
                  const SizedBox(height: 32),
                  CircularProgressIndicator(color: AppColors.secondary),
                ],
                if (status == NetworkStatus.online) ...[
                  const SizedBox(height: 32),
                  _buildContinueButton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange,
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Offline',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Beberapa fitur tidak tersedia',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Coba',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(LucideIcons.refreshCw, size: 18),
        label: const Text('Coba Lagi'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Lanjutkan'),
      ),
    );
  }

  Widget _buildOfflineTips() {
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
              Icon(LucideIcons.lightbulb, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTip('• Periksa koneksi WiFi atau data seluler'),
          _buildTip('• Coba restart koneksi internet'),
          _buildTip('• Pastikan mode pesawat tidak aktif'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 24),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// Network-aware wrapper widget
class NetworkAwareWrapper extends StatefulWidget {
  final Widget onlineChild;
  final Widget? offlineChild;
  final bool showBanner;

  const NetworkAwareWrapper({
    super.key,
    required this.onlineChild,
    this.offlineChild,
    this.showBanner = true,
  });

  @override
  State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState extends State<NetworkAwareWrapper> {
  NetworkStatus _status = NetworkStatus.online;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    // TODO: Implement actual network check
    // For now, mock as online
    setState(() {
      _status = NetworkStatus.online;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == NetworkStatus.offline) {
      if (widget.offlineChild != null) {
        if (widget.showBanner) {
          return Column(
            children: [
              _buildBanner(),
              Expanded(child: widget.offlineChild!),
            ],
          );
        }
        return widget.offlineChild!;
      }
      return NetworkErrorWidget(status: _status, onRetry: _retry);
    }

    if (widget.showBanner && _status != NetworkStatus.online) {
      return Column(
        children: [
          _buildBanner(),
          Expanded(child: widget.onlineChild),
        ],
      );
    }

    return widget.onlineChild;
  }

  Widget _buildBanner() {
    Color backgroundColor;
    IconData icon;
    String message;

    switch (_status) {
      case NetworkStatus.offline:
        backgroundColor = Colors.orange;
        icon = LucideIcons.wifiOff;
        message = 'Tidak ada koneksi internet';
        break;
      case NetworkStatus.connecting:
        backgroundColor = AppColors.secondary;
        icon = LucideIcons.loader;
        message = 'Menghubungkan...';
        break;
      case NetworkStatus.online:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_status == NetworkStatus.offline)
            TextButton(
              onPressed: _retry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Coba',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      _status = NetworkStatus.connecting;
    });
    _checkNetworkStatus();
  }
}
