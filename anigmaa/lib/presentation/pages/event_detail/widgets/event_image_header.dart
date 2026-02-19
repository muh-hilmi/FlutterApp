import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/entities/event.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventImageHeader extends StatelessWidget {
  final Event event;
  final PageController pageController;
  final int currentImageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onShareTap;
  final VoidCallback onReportTap;
  final VoidCallback onBackPressed;
  final Function(int) onImageTap;

  const EventImageHeader({
    super.key,
    required this.event,
    required this.pageController,
    required this.currentImageIndex,
    required this.onPageChanged,
    required this.onShareTap,
    required this.onReportTap,
    required this.onBackPressed,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasEnded = event.hasEnded;

    // Debug: Log image URLs for detail page
    if (event.fullImageUrls.isNotEmpty) {
      AppLogger().info('[EventDetail] Event "${event.title}" has ${event.fullImageUrls.length} image(s)');
      AppLogger().info('[EventDetail] First image URL: ${event.fullImageUrls.first}');
    }

    return Stack(
      children: [
        _buildImageCarousel(screenWidth),
        _buildGradientOverlay(),
        if (hasEnded) _buildEndedOverlay(),
        if (!hasEnded) _buildPriceBadge(),
        if (event.fullImageUrls.length > 1) _buildImageIndicators(),
        _buildFloatingAppBar(),
      ],
    );
  }

  Widget _buildImageCarousel(double screenWidth) {
    if (event.fullImageUrls.isNotEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenWidth * 1.5,
          minHeight: screenWidth * 0.8,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: event.fullImageUrls.length > 4 ? 4 : event.fullImageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => onImageTap(index),
                child: CachedNetworkImage(
                  imageUrl: event.fullImageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 300),
                  errorWidget: (context, url, error) {
                    AppLogger().error('[EventDetail] Failed to load image');
                    AppLogger().error('[EventDetail] URL: $url');
                    AppLogger().error('[EventDetail] Error: $error');
                    return _buildImagePlaceholder();
                  },
                  placeholder: (context, url) => _buildLoadingPlaceholder(),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: 1,
        child: _buildImagePlaceholder(),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.cardSurface,
      child: Center(
        child: Icon(
          Icons.event_rounded,
          size: 140,
          color: AppColors.secondary.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.cardSurface,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.transparent,
                AppColors.primary.withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.2, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndedOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              'SELESAI',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBadge() {
    return Positioned(
      bottom: 24,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Mulai dari',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  event.isFree
                      ? 'GRATIS'
                      : CurrencyFormatter.formatToCompactNoPrefix(event.price!),
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageIndicators() {
    return Positioned(
      bottom: 24,
      left: 20,
      child: Row(
        children: List.generate(
          event.fullImageUrls.length > 4 ? 4 : event.fullImageUrls.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 6),
            width: currentImageIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: currentImageIndex == index
                  ? AppColors.secondary
                  : AppColors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBackButton(),
              _buildMoreButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onBackPressed,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.white,
          size: 22,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (value) {
          if (value == 'share') {
            onShareTap();
          } else if (value == 'report') {
            onReportTap();
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share_rounded, size: 18),
                SizedBox(width: 8),
                Text('Bagikan Event'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Laporkan Event',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}