import '../../domain/entities/ranked_feed.dart';

class RankedFeedModel extends RankedFeed {
  const RankedFeedModel({
    super.trendingEvent,
    super.forYouPosts,
    super.forYouEvents,
    super.chillEvents,
    super.hariIniEvents,
    super.gratisEvents,
    super.bayarEvents,
  });

  factory RankedFeedModel.fromJson(Map<String, dynamic> json) {
    return RankedFeedModel(
      trendingEvent: List<String>.from(json['trending_event'] ?? []),
      forYouPosts: List<String>.from(json['for_you_posts'] ?? []),
      forYouEvents: List<String>.from(json['for_you_events'] ?? []),
      chillEvents: List<String>.from(json['chill_events'] ?? []),
      hariIniEvents: List<String>.from(json['hari_ini_events'] ?? []),
      gratisEvents: List<String>.from(json['gratis_events'] ?? []),
      bayarEvents: List<String>.from(json['bayar_events'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trending_event': trendingEvent,
      'for_you_posts': forYouPosts,
      'for_you_events': forYouEvents,
      'chill_events': chillEvents,
      'hari_ini_events': hariIniEvents,
      'gratis_events': gratisEvents,
      'bayar_events': bayarEvents,
    };
  }

  factory RankedFeedModel.fromEntity(RankedFeed feed) {
    return RankedFeedModel(
      trendingEvent: feed.trendingEvent,
      forYouPosts: feed.forYouPosts,
      forYouEvents: feed.forYouEvents,
      chillEvents: feed.chillEvents,
      hariIniEvents: feed.hariIniEvents,
      gratisEvents: feed.gratisEvents,
      bayarEvents: feed.bayarEvents,
    );
  }
}

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    super.preferredTags,
    super.likedContents,
    super.followedAuthors,
    super.avgViewTimeMs,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      preferredTags: Map<String, double>.from(json['preferred_tags'] ?? {}),
      likedContents: List<String>.from(json['liked_contents'] ?? []),
      followedAuthors: List<String>.from(json['followed_authors'] ?? []),
      avgViewTimeMs: json['avg_view_time_ms'] as int? ?? 30000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'preferred_tags': preferredTags,
      'liked_contents': likedContents,
      'followed_authors': followedAuthors,
      'avg_view_time_ms': avgViewTimeMs,
    };
  }

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      id: profile.id,
      preferredTags: profile.preferredTags,
      likedContents: profile.likedContents,
      followedAuthors: profile.followedAuthors,
      avgViewTimeMs: profile.avgViewTimeMs,
    );
  }
}

class TodayWindowModel extends TodayWindow {
  const TodayWindowModel({
    required super.startUtc,
    required super.endUtc,
  });

  factory TodayWindowModel.fromJson(Map<String, dynamic> json) {
    return TodayWindowModel(
      startUtc: DateTime.parse(json['start_utc'] as String),
      endUtc: DateTime.parse(json['end_utc'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_utc': startUtc.toIso8601String(),
      'end_utc': endUtc.toIso8601String(),
    };
  }

  factory TodayWindowModel.fromEntity(TodayWindow window) {
    return TodayWindowModel(
      startUtc: window.startUtc,
      endUtc: window.endUtc,
    );
  }
}

class RankingRequestModel extends RankingRequest {
  const RankingRequestModel({
    required super.userProfile,
    super.events,
    super.posts,
    super.todayWindow,
  });

  factory RankingRequestModel.fromJson(Map<String, dynamic> json) {
    return RankingRequestModel(
      userProfile: UserProfileModel.fromJson(json['user_profile']),
      events: List<Map<String, dynamic>>.from(
        (json['contents']?['events'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      posts: List<Map<String, dynamic>>.from(
        (json['contents']?['posts'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      todayWindow: json['today_window'] != null
          ? TodayWindowModel.fromJson(json['today_window'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'user_profile': (userProfile as UserProfileModel).toJson(),
      'contents': {
        'events': events,
        'posts': posts,
      },
    };

    if (todayWindow != null) {
      json['today_window'] = (todayWindow as TodayWindowModel).toJson();
    }

    return json;
  }

  factory RankingRequestModel.fromEntity(RankingRequest request) {
    return RankingRequestModel(
      userProfile: UserProfileModel.fromEntity(request.userProfile),
      events: request.events,
      posts: request.posts,
      todayWindow: request.todayWindow != null
          ? TodayWindowModel.fromEntity(request.todayWindow!)
          : null,
    );
  }
}
