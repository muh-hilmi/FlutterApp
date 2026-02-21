import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

/// A safe network image widget that handles decoding errors gracefully
class SafeNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? fadeInDuration;
  final Map<String, String>? headers;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration,
    this.headers,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Validate URL before attempting to load
    if (!_isValidImageUrl(widget.imageUrl)) {
      return widget.errorWidget ?? _buildDefaultError('Invalid image URL');
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      httpHeaders: widget.headers,
      placeholder: (context, url) =>
          widget.placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        // Log detailed error for debugging
        debugPrint('Image loading error for URL: $url');
        debugPrint('Error details: $error');

        // Check if it's a decoding error
        if (error.toString().contains('DecodeException') ||
            error.toString().contains('Failed to decode')) {
          return _buildDecodingErrorWidget();
        }

        return widget.errorWidget ?? _buildDefaultError(error.toString());
      },
      memCacheWidth: widget.memCacheWidth ?? widget.width?.toInt(),
      memCacheHeight: widget.memCacheHeight ?? widget.height?.toInt(),
      fadeInDuration:
          widget.fadeInDuration ?? const Duration(milliseconds: 300),
      cacheKey: _generateCacheKey(widget.imageUrl),
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _generateCacheKey(String url) {
    // Add version to cache key to handle stale images
    return '${url}_v2';
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultError(String error) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 40, color: AppColors.border),
          const SizedBox(height: 8),
          if (widget.height != null && widget.height! > 100)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Failed to load image',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDecodingErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.red[400],
          ),
          const SizedBox(height: 8),
          if (widget.height != null && widget.height! > 100)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Unsupported image format',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom cache manager with better error handling
class CustomCacheManager extends CacheManager {
  static const key = 'customCacheKey';

  static CustomCacheManager? _instance;

  factory CustomCacheManager() {
    return _instance ??= CustomCacheManager._();
  }

  CustomCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
}
