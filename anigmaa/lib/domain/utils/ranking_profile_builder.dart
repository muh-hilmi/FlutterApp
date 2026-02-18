import '../entities/ranked_feed.dart';
import '../entities/user.dart';
import '../entities/post.dart';
import '../entities/event.dart';

/// Utility class to build user profile for the ranking API
/// based on user behavior and preferences
class RankingProfileBuilder {
  /// Build a user profile for ranking from a User entity
  static UserProfile fromUser(
    User user, {
    List<Post>? likedPosts,
    List<Event>? attendedEvents,
    List<String>? followedAuthorIds,
    int? avgViewTimeMs,
  }) {
    // Calculate preferred tags from user interests
    final preferredTags = <String, double>{};

    // Start with user's declared interests
    for (final interest in user.interests) {
      preferredTags[interest] = 1.0;
    }

    // Boost tags from liked content
    if (likedPosts != null && likedPosts.isNotEmpty) {
      final tagFrequency = <String, int>{};
      for (final post in likedPosts) {
        for (final tag in post.hashtags) {
          tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
        }
      }

      // Normalize tag frequency to weights (0.0 - 2.0)
      final maxFrequency = tagFrequency.values.isEmpty
          ? 1
          : tagFrequency.values.reduce((a, b) => a > b ? a : b);

      for (final entry in tagFrequency.entries) {
        final weight = (entry.value / maxFrequency) * 2.0;
        preferredTags[entry.key] = (preferredTags[entry.key] ?? 0) + weight;
      }
    }

    // Boost tags from attended events
    if (attendedEvents != null && attendedEvents.isNotEmpty) {
      final categoryFrequency = <String, int>{};
      for (final event in attendedEvents) {
        final categoryName = event.category.name;
        categoryFrequency[categoryName] = (categoryFrequency[categoryName] ?? 0) + 1;
      }

      final maxFrequency = categoryFrequency.values.isEmpty
          ? 1
          : categoryFrequency.values.reduce((a, b) => a > b ? a : b);

      for (final entry in categoryFrequency.entries) {
        final weight = (entry.value / maxFrequency) * 1.5;
        preferredTags[entry.key] = (preferredTags[entry.key] ?? 0) + weight;
      }
    }

    // Get liked content IDs
    final likedContentIds = likedPosts?.map((p) => p.id).toList() ?? [];

    return UserProfile(
      id: user.id,
      preferredTags: preferredTags,
      likedContents: likedContentIds,
      followedAuthors: followedAuthorIds ?? [],
      avgViewTimeMs: avgViewTimeMs ?? 30000,
    );
  }

  /// Build today window based on user's timezone
  /// If location is not available, defaults to UTC
  static TodayWindow buildTodayWindow({
    String? userTimezone,
  }) {
    final now = DateTime.now().toUtc();

    // For simplicity, use UTC day boundaries
    // In production, you might want to use timezone package
    final startUtc = DateTime.utc(now.year, now.month, now.day);
    final endUtc = startUtc.add(const Duration(days: 1));

    return TodayWindow(
      startUtc: startUtc,
      endUtc: endUtc,
    );
  }

  /// Calculate average view time from user behavior
  /// This is a placeholder - in production, you'd track this in analytics
  static int calculateAvgViewTime(User user) {
    // Default to 30 seconds
    // In production, fetch from analytics service
    return 30000;
  }
}
