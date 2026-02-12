class RankedFeed {
  final List<String> trendingEvent;
  final List<String> forYouPosts;
  final List<String> forYouEvents;
  final List<String> chillEvents;
  final List<String> hariIniEvents;
  final List<String> gratisEvents;
  final List<String> bayarEvents;

  const RankedFeed({
    this.trendingEvent = const [],
    this.forYouPosts = const [],
    this.forYouEvents = const [],
    this.chillEvents = const [],
    this.hariIniEvents = const [],
    this.gratisEvents = const [],
    this.bayarEvents = const [],
  });

  RankedFeed copyWith({
    List<String>? trendingEvent,
    List<String>? forYouPosts,
    List<String>? forYouEvents,
    List<String>? chillEvents,
    List<String>? hariIniEvents,
    List<String>? gratisEvents,
    List<String>? bayarEvents,
  }) {
    return RankedFeed(
      trendingEvent: trendingEvent ?? this.trendingEvent,
      forYouPosts: forYouPosts ?? this.forYouPosts,
      forYouEvents: forYouEvents ?? this.forYouEvents,
      chillEvents: chillEvents ?? this.chillEvents,
      hariIniEvents: hariIniEvents ?? this.hariIniEvents,
      gratisEvents: gratisEvents ?? this.gratisEvents,
      bayarEvents: bayarEvents ?? this.bayarEvents,
    );
  }
}

class UserProfile {
  final String id;
  final Map<String, double> preferredTags;
  final List<String> likedContents;
  final List<String> followedAuthors;
  final int avgViewTimeMs;

  const UserProfile({
    required this.id,
    this.preferredTags = const {},
    this.likedContents = const [],
    this.followedAuthors = const [],
    this.avgViewTimeMs = 30000,
  });

  UserProfile copyWith({
    String? id,
    Map<String, double>? preferredTags,
    List<String>? likedContents,
    List<String>? followedAuthors,
    int? avgViewTimeMs,
  }) {
    return UserProfile(
      id: id ?? this.id,
      preferredTags: preferredTags ?? this.preferredTags,
      likedContents: likedContents ?? this.likedContents,
      followedAuthors: followedAuthors ?? this.followedAuthors,
      avgViewTimeMs: avgViewTimeMs ?? this.avgViewTimeMs,
    );
  }
}

class TodayWindow {
  final DateTime startUtc;
  final DateTime endUtc;

  const TodayWindow({
    required this.startUtc,
    required this.endUtc,
  });

  TodayWindow copyWith({
    DateTime? startUtc,
    DateTime? endUtc,
  }) {
    return TodayWindow(
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
    );
  }
}

class RankingRequest {
  final UserProfile userProfile;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> posts;
  final TodayWindow? todayWindow;

  const RankingRequest({
    required this.userProfile,
    this.events = const [],
    this.posts = const [],
    this.todayWindow,
  });

  RankingRequest copyWith({
    UserProfile? userProfile,
    List<Map<String, dynamic>>? events,
    List<Map<String, dynamic>>? posts,
    TodayWindow? todayWindow,
  }) {
    return RankingRequest(
      userProfile: userProfile ?? this.userProfile,
      events: events ?? this.events,
      posts: posts ?? this.posts,
      todayWindow: todayWindow ?? this.todayWindow,
    );
  }
}
