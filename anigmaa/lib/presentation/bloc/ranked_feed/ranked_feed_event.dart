import 'package:equatable/equatable.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/post.dart';

abstract class RankedFeedEvent extends Equatable {
  const RankedFeedEvent();

  @override
  List<Object?> get props => [];
}

class LoadRankedFeed extends RankedFeedEvent {
  final List<Post> posts;
  final List<Event> events;

  const LoadRankedFeed({
    required this.posts,
    required this.events,
  });

  @override
  List<Object?> get props => [posts, events];
}

class RefreshRankedFeed extends RankedFeedEvent {
  final List<Post> posts;
  final List<Event> events;

  const RefreshRankedFeed({
    required this.posts,
    required this.events,
  });

  @override
  List<Object?> get props => [posts, events];
}
