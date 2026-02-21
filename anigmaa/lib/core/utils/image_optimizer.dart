import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/safe_network_image.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

/// Image optimization utilities for better performance
class ImageOptimizer {
  static final ImageOptimizer _instance = ImageOptimizer._internal();
  factory ImageOptimizer() => _instance;
  ImageOptimizer._internal();

  /// Optimize network image with caching and proper sizing
  static Widget optimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration? fadeInDuration,
    Map<String, String>? headers,
  }) {
    // Use SafeNetworkImage for better error handling
    return SafeNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: errorWidget ?? _buildDefaultError(),
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      headers: headers,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }

  /// Build default placeholder widget
  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textTertiary),
        ),
      ),
    );
  }

  /// Build default error widget
  static Widget _buildDefaultError() {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Center(
        child: Icon(Icons.broken_image, color: AppColors.textTertiary, size: 40),
      ),
    );
  }

  /// Resize image to reduce memory usage
  static Future<ui.Image?> resizeImage(
    ui.Image originalImage, {
    int? targetWidth,
    int? targetHeight,
  }) async {
    if (targetWidth == null && targetHeight == null) {
      return originalImage;
    }

    final originalWidth = originalImage.width.toDouble();
    final originalHeight = originalImage.height.toDouble();

    // Calculate aspect ratio
    final aspectRatio = originalWidth / originalHeight;

    // Calculate target dimensions maintaining aspect ratio
    double newWidth;
    double newHeight;

    if (targetWidth != null && targetHeight != null) {
      newWidth = targetWidth.toDouble();
      newHeight = targetHeight.toDouble();
    } else if (targetWidth != null) {
      newWidth = targetWidth.toDouble();
      newHeight = targetWidth / aspectRatio;
    } else {
      newHeight = targetHeight!.toDouble();
      newWidth = targetHeight * aspectRatio;
    }

    // Create recorder for resized image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw resized image
    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(0, 0, originalWidth, originalHeight),
      Rect.fromLTWH(0, 0, newWidth, newHeight),
      Paint(),
    );

    // Create resized image from recorder
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(
      newWidth.toInt(),
      newHeight.toInt(),
    );

    return resizedImage;
  }

  /// Compress image file
  static Future<File?> compressImage(
    File imageFile, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Read image bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Resize if needed
      ui.Image? resizedImage = image;
      if (maxWidth != null || maxHeight != null) {
        resizedImage = await resizeImage(
          image,
          targetWidth: maxWidth,
          targetHeight: maxHeight,
        );
      }

      // Encode to bytes with compression
      final ByteData? byteData = resizedImage != null
          ? await resizedImage.toByteData(format: ui.ImageByteFormat.png)
          : null;

      if (byteData == null) return null;

      final Uint8List compressedBytes = byteData.buffer.asUint8List();

      // Save compressed image
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = path.basenameWithoutExtension(imageFile.path);
      final String filePath = path.join(
        tempDir.path,
        '${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final File compressedFile = File(filePath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Get image size before loading
  static Future<Size?> getImageSize(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('Error getting image size: $e');
      return null;
    }
  }

  /// Check if image needs optimization
  static bool needsOptimization(File imageFile) {
    // Check file size (5MB threshold)
    final fileSize = imageFile.lengthSync();
    if (fileSize > 5 * 1024 * 1024) return true;

    // You can add more criteria here
    return false;
  }

  /// Generate thumbnail from image
  static Future<File?> generateThumbnail(
    File imageFile, {
    int thumbnailSize = 200,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Resize to thumbnail size
      final resizedImage = await resizeImage(
        image,
        targetWidth: thumbnailSize,
        targetHeight: thumbnailSize,
      );

      if (resizedImage == null) return null;

      // Encode thumbnail
      final ByteData? byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      final Uint8List thumbnailBytes = byteData.buffer.asUint8List();

      // Save thumbnail
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = path.basenameWithoutExtension(imageFile.path);
      final String filePath = path.join(
        tempDir.path,
        '${fileName}_thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final File thumbnailFile = File(filePath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      return thumbnailFile;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Clear image cache
  static void clearCache() {
    PaintingBinding.instance.imageCache.clear();
  }

  /// Safely precache image with error handling
  static void safePrecacheImage(
    BuildContext context,
    String imageUrl, {
    double? width,
    double? height,
  }) {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return;

    try {
      precacheImage(
        CachedNetworkImageProvider(
          imageUrl,
          maxWidth: width?.toInt(),
          maxHeight: height?.toInt(),
        ),
        context,
        onError: (e, stackTrace) {
          // Swallow errors to prevent log spam
          // debugPrint('Failed to precache: $e');
        },
      );
    } catch (e) {
      // Silently fail
    }
  }
}

/// Custom cached image widget with advanced features
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? fadeInDuration;
  final bool enableMemoryCache;
  final bool enableDiskCache;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableMemoryCache && !enableDiskCache) {
      // Use regular network image if caching is disabled
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? ImageOptimizer._buildDefaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? ImageOptimizer._buildDefaultError();
        },
      );
    }

    return ImageOptimizer.optimizedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fadeInDuration: fadeInDuration,
    );
  }
}
