import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/posts/posts_bloc.dart';
import '../../../bloc/posts/posts_event.dart';
import '../../create_post/create_post_screen.dart';

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
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.feed_outlined,
              size: 60,
              color: Color(0xFFBBC863),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Halo! Selamat datang di flyerr 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Yuk gas connect sama orang-orang keren\ndan ikutan event seru!',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF000000),
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
              backgroundColor: const Color(0xFFBBC863),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: const Text(
              'Bikin Post',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
