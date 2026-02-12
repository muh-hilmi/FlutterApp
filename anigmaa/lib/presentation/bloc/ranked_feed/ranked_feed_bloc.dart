import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/ranked_feed.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/get_ranked_feed.dart';
import '../../../domain/utils/ranking_profile_builder.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/event_model.dart';
import '../../../core/utils/logger.dart';
import 'ranked_feed_event.dart';
import 'ranked_feed_state.dart';

class RankedFeedBloc extends Bloc<RankedFeedEvent, RankedFeedState> {
  final GetRankedFeed getRankedFeed;
  final GetCurrentUser getCurrentUser;

  RankedFeedBloc({
    required this.getRankedFeed,
    required this.getCurrentUser,
  }) : super(RankedFeedInitial()) {
    on<LoadRankedFeed>(_onLoadRankedFeed);
    on<RefreshRankedFeed>(_onRefreshRankedFeed);
  }

  Future<void> _onLoadRankedFeed(
    LoadRankedFeed event,
    Emitter<RankedFeedState> emit,
  ) async {
    emit(RankedFeedLoading());

    try {
      // Get current user for profile building
      final userResult = await getCurrentUser(NoParams());

      await userResult.fold(
        (failure) async {
          emit(RankedFeedError('Failed to get user profile: ${failure.toString()}'));
        },
        (user) async {
          // Build user profile for ranking
          final userProfile = RankingProfileBuilder.fromUser(user);

          // Build today window
          final todayWindow = RankingProfileBuilder.buildTodayWindow();

          // Convert posts and events to JSON
          final postsJson = event.posts
              .map((p) => PostModel.fromEntity(p).toJson())
              .toList();
          final eventsJson = event.events
              .map((e) => EventModel.fromEntity(e).toJson())
              .toList();

          // Create ranking request
          final request = RankingRequest(
            userProfile: userProfile,
            posts: postsJson,
            events: eventsJson,
            todayWindow: todayWindow,
          );

          // Uncomment for debugging:
          // logger.d('[RankedFeedBloc] Requesting feed - Posts: ${event.posts.length}, Events: ${event.events.length}');

          // Call ranking API
          final result = await getRankedFeed(request);

          result.fold(
            (failure) {
              logger.e('[RankedFeedBloc] Error: $failure');
              emit(RankedFeedError('Failed to rank feed: ${failure.toString()}'));
            },
            (rankedFeed) {
              emit(RankedFeedLoaded(
                rankedFeed: rankedFeed,
                posts: event.posts,
                events: event.events,
              ));
            },
          );
        },
      );
    } catch (e) {
      logger.e('[RankedFeedBloc] Exception: $e');
      emit(RankedFeedError('Exception ranking feed: $e'));
    }
  }

  Future<void> _onRefreshRankedFeed(
    RefreshRankedFeed event,
    Emitter<RankedFeedState> emit,
  ) async {
    // Reuse the same logic as LoadRankedFeed
    await _onLoadRankedFeed(
      LoadRankedFeed(posts: event.posts, events: event.events),
      emit,
    );
  }
}
