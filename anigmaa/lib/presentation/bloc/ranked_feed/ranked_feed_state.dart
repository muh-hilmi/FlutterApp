import 'package:equatable/equatable.dart';
import '../../../domain/entities/ranked_feed.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/post.dart';

abstract class RankedFeedState extends Equatable {
  const RankedFeedState();

  @override
  List<Object?> get props => [];
}

class RankedFeedInitial extends RankedFeedState {}

class RankedFeedLoading extends RankedFeedState {}

class RankedFeedLoaded extends RankedFeedState {
  final RankedFeed rankedFeed;
  final List<Post> posts;
  final List<Event> events;

  const RankedFeedLoaded({
    required this.rankedFeed,
    required this.posts,
    required this.events,
  });

  // Helper methods to get actual objects from ranked IDs
  List<Event> get trendingEvents => _getEventsByIds(rankedFeed.trendingEvent);
  List<Post> get forYouPosts => _getPostsByIds(rankedFeed.forYouPosts);
  List<Event> get forYouEvents => _getEventsByIds(rankedFeed.forYouEvents);
  List<Event> get chillEvents => _getEventsByIds(rankedFeed.chillEvents);
  List<Event> get hariIniEvents => _getEventsByIds(rankedFeed.hariIniEvents);
  List<Event> get gratisEvents => _getEventsByIds(rankedFeed.gratisEvents);
  List<Event> get bayarEvents => _getEventsByIds(rankedFeed.bayarEvents);

  List<Post> _getPostsByIds(List<String> ids) {
    return ids
        .map((id) => posts.firstWhere(
              (p) => p.id == id,
              orElse: () => throw Exception('Post not found: $id'),
            ))
        .toList();
  }

  List<Event> _getEventsByIds(List<String> ids) {
    return ids
        .map((id) => events.firstWhere(
              (e) => e.id == id,
              orElse: () => throw Exception('Event not found: $id'),
            ))
        .toList();
  }

  RankedFeedLoaded copyWith({
    RankedFeed? rankedFeed,
    List<Post>? posts,
    List<Event>? events,
  }) {
    return RankedFeedLoaded(
      rankedFeed: rankedFeed ?? this.rankedFeed,
      posts: posts ?? this.posts,
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [rankedFeed, posts, events];
}

class RankedFeedError extends RankedFeedState {
  final String message;

  const RankedFeedError(this.message);

  @override
  List<Object?> get props => [message];
}
