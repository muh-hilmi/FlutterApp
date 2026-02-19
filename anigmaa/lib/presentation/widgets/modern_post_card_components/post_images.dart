import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PostImages extends StatelessWidget {
  final List<String> imageUrls;

  const PostImages({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length == 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: imageUrls[0],
            width: double.infinity,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            memCacheWidth: 800,
            memCacheHeight: 600,
            placeholder: (context, url) => Container(
              height: 300,
              color: AppColors.surfaceAlt,
            ),
            errorWidget: (context, url, error) {
              return Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(Icons.image_not_supported_rounded, size: 40, color: AppColors.textTertiary),
                ),
              );
            },
          ),
        ),
      );
    }

    // Grid for multiple images with rounded corners
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: imageUrls.length > 4 ? 4 : imageUrls.length,
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  memCacheWidth: 400,
                  memCacheHeight: 400,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceAlt,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceAlt,
                    child: Icon(Icons.image_not_supported_rounded, color: AppColors.textTertiary),
                  ),
                ),
                if (index == 3 && imageUrls.length > 4)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.6),
                          AppColors.primary.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+${imageUrls.length - 4}',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
