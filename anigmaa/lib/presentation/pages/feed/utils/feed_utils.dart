import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/entities/post.dart';

class FeedUtils {
  static List<Post> sortPostsByRanking(
    List<Post> posts,
    List<String> rankedIds,
  ) {
    if (rankedIds.isEmpty) return posts;

    // Create map for O(1) lookup
    final postMap = {for (var post in posts) post.id: post};

    // Sort posts according to ranked IDs
    final sortedPosts = <Post>[];
    for (final id in rankedIds) {
      if (postMap.containsKey(id)) {
        sortedPosts.add(postMap[id]!);
      }
    }

    // Add remaining posts that weren't in ranking
    for (final post in posts) {
      if (!rankedIds.contains(post.id)) {
        sortedPosts.add(post);
      }
    }

    return sortedPosts;
  }

  static void precacheVisibleImages(BuildContext context, List<Post> posts) {
    // Take first 15 posts
    final visiblePosts = posts.take(15).toList();

    for (final post in visiblePosts) {
      if (post.imageUrls.isNotEmpty) {
        for (final imageUrl in post.imageUrls) {
          precacheImage(
            CachedNetworkImageProvider(imageUrl, maxWidth: 800, maxHeight: 600),
            context,
          );
        }
      }
    }
  }

  static void precacheUpcomingImages(
    BuildContext context,
    List<Post> feedPosts,
    ScrollController scrollController,
  ) {
    if (feedPosts.isEmpty) return;
    if (!scrollController.hasClients) return;

    // Calculate current scroll position in terms of items
    final currentScroll = scrollController.position.pixels;
    final itemHeight = 500.0; // Approximate height of a post card
    final currentIndex = (currentScroll / itemHeight).floor();

    // Precache next 10 posts
    final startIndex = currentIndex + 1;
    final endIndex = (startIndex + 10).clamp(0, feedPosts.length);

    for (int i = startIndex; i < endIndex; i++) {
      final post = feedPosts[i];
      if (post.imageUrls.isNotEmpty) {
        for (final imageUrl in post.imageUrls) {
          precacheImage(
            CachedNetworkImageProvider(imageUrl, maxWidth: 800, maxHeight: 600),
            context,
          );
        }
      }
    }
  }
}
