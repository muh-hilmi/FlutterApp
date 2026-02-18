import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Enhanced Image widget with comprehensive error handling
class EnhancedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableRetry;
  final int maxRetries;
  final Duration retryDelay;

  const EnhancedImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableRetry = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  Widget build(BuildContext context) {
    // Handle null or empty URL
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget('No image URL provided');
    }

    // Validate URL format
    if (!_isValidUrl(imageUrl!)) {
      return _buildErrorWidget('Invalid URL format');
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      // Use smaller cache dimensions to prevent memory issues
      memCacheWidth: _calculateCacheWidth(),
      memCacheHeight: _calculateCacheHeight(),
      // Set placeholder
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      // Enhanced error handling
      errorWidget: (context, url, error) {
        debugPrint('=== Enhanced Image Error ===');
        debugPrint('URL: $url');
        debugPrint('Error: $error');
        debugPrint('Error Type: ${error.runtimeType}');

        // Check for specific error types
        if (error.toString().contains('DecodeException') ||
            error.toString().contains('Failed to decode') ||
            error.toString().contains('unimplemented')) {
          return _buildDecodingErrorWidget();
        }

        if (error.toString().contains('404') ||
            error.toString().contains('Not Found')) {
          return _buildErrorWidget('Image not found');
        }

        if (error.toString().contains('Network') ||
            error.toString().contains('Connection')) {
          if (enableRetry) {
            return _buildRetryWidget();
          }
          return _buildErrorWidget('Network error');
        }

        return _buildErrorWidget('Failed to load image');
      },
      // Add headers to simulate browser request
      httpHeaders: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Encoding': 'gzip, deflate',
        'Cache-Control': 'no-cache',
      },
      // Set fade effects
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Configure cache
      cacheKey: _generateCacheKey(imageUrl!),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _generateCacheKey(String url) {
    // Create a unique cache key that includes URL version
    final uri = Uri.parse(url);
    return '${uri.host}_${uri.path}_${uri.query}_v2';
  }

  int? _calculateCacheWidth() {
    if (width != null) {
      // Scale down cache size to save memory
      return (width! * 2).round().clamp(100, 1200);
    }
    return 600; // Default cache width
  }

  int? _calculateCacheHeight() {
    if (height != null) {
      // Scale down cache size to save memory
      return (height! * 2).round().clamp(100, 1200);
    }
    return 600; // Default cache height
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                if (height != null && height! > 100)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildDecodingErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.red[400],
            ),
            const SizedBox(height: 8),
            if (height != null && height! > 100)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Unsupported image format',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryWidget() {
    int retryCount = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        if (retryCount < maxRetries) {
          Future.delayed(retryDelay, () {
            if (retryCount < maxRetries) {
              setState(() {
                retryCount++;
              });
              // Trigger rebuild to retry
            }
          });

          return _buildPlaceholder();
        }

        return _buildErrorWidget('Failed after $maxRetries attempts');
      },
    );
  }
}

/// Extension to make using EnhancedImage easier
extension EnhancedImageExtension on String? {
  Widget toEnhancedImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return EnhancedImage(
      imageUrl: this,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}