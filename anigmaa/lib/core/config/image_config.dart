import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/enhanced_image.dart';

/// Global configuration for image handling
class ImageConfig {
  static bool _initialized = false;

  /// Initialize image configuration
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (!kDebugMode) {
      // Reduce image cache size in release mode
      PaintingBinding.instance.imageCache.maximumSize = 50;
      PaintingBinding.instance.imageCache.clear();
    }

    // Preconfigure error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('image') ||
          details.exception.toString().contains('Image')) {
        debugPrint('Suppressed image error in release mode');
        return;
      }
      FlutterError.presentError(details);
    };
  }

  /// Preferred widget for loading network images with error handling
  static Widget networkImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return EnhancedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  /// Constants for image dimensions
  static const int thumbnailSize = 150;
  static const int mediumSize = 400;
  static const int largeSize = 800;

  /// Get appropriate cache size based on display size
  static int getCacheSize(double displaySize, {int maxSize = 1200}) {
    return (displaySize * 2).round().clamp(100, maxSize);
  }
}