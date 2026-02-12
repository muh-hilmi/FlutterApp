import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/entities/event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventImageHeader extends StatefulWidget {
  final Event event;
  final Function(int) onImageIndexChanged;

  const EventImageHeader({
    super.key,
    required this.event,
    required this.onImageIndexChanged,
  });

  @override
  State<EventImageHeader> createState() => _EventImageHeaderState();
}

class _EventImageHeaderState extends State<EventImageHeader> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1:1 Aspect Ratio or slightly taller used in the original design
    // We'll stick to 1:1 for a strong modern look
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Image Slider / Placeholder
          _buildImageSlider(),

          // 2. Gradients
          _buildGradients(),

          // 3. Status Badge (Ended)
          if (widget.event.hasEnded) _buildEndedBadge(),

          // 4. Category Tag
          Positioned(
            bottom: widget.event.fullImageUrls.length > 1 ? 40 : 20,
            left: 20,
            child: _buildCategoryTag(),
          ),

          // 5. Page Indicators (if multiple images)
          if (widget.event.fullImageUrls.length > 1)
            Positioned(bottom: 20, left: 20, child: _buildPageIndicators()),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    if (widget.event.fullImageUrls.isEmpty) {
      return Container(
        color: AppColors.surfaceAlt,
        child: Center(
          child: Icon(
            Icons.event_rounded,
            size: 80,
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        widget.onImageIndexChanged(index);
      },
      itemCount: widget.event.fullImageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // TODO: Open Full Screen Image Viewer
          },
          child: CachedNetworkImage(
            imageUrl: widget.event.fullImageUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surfaceAlt,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceAlt,
              child: const Icon(Icons.error_outline, color: AppColors.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradients() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(
              alpha: 0.6,
            ), // Top for back button visibility
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6), // Bottom for text visibility
          ],
          stops: const [0.0, 0.2, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildEndedBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          'SELESAI',
          style: AppTextStyles.button.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary, // Electric Lime
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.event.category.name.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary, // Black Text
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.event.fullImageUrls.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: _currentIndex == index ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: _currentIndex == index
                ? AppColors.secondary
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
