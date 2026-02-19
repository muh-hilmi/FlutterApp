import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PostContent extends StatelessWidget {
  final String content;

  const PostContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        height: 1.5,
        letterSpacing: -0.2,
      ),
    );
  }
}
