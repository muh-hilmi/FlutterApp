import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/posts/posts_bloc.dart';
import '../../../bloc/posts/posts_event.dart';
import '../../create_post/create_post_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.feed_outlined,
              size: 60,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Halo! Selamat datang di flyerr 👋',
            style: AppTextStyles.h2.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Yuk gas connect sama orang-orang keren\ndan ikutan event seru!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await CreatePostSheet.show(context);

              if (result != null) {
                if (context.mounted) {
                  context.read<PostsBloc>().add(CreatePostRequested(result));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: Text(
              'Bikin Post',
              style: AppTextStyles.bodyLargeBold.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
