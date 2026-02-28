import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core
import 'core/services/auth_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/api_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/auto_refresh_service.dart';
import 'core/storage/cache_storage_service.dart';
import 'core/storage/location_cache_service.dart';
import 'core/api/dio_client.dart';
import 'core/auth/auth_bloc.dart';

// Domain
import 'domain/repositories/event_repository.dart';
import 'domain/repositories/post_repository.dart';
import 'domain/repositories/ticket_repository.dart';
import 'domain/repositories/community_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/ranking_repository.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/repositories/payment_repository.dart';
import 'domain/usecases/get_events.dart';
import 'domain/usecases/get_events_by_category.dart';
import 'domain/usecases/get_nearby_events.dart'; // Added import
import 'domain/usecases/get_event_by_id.dart';
import 'domain/usecases/create_event.dart';
import 'domain/usecases/update_event.dart';
import 'domain/usecases/toggle_event_interest.dart';
import 'domain/usecases/upload_image.dart';
import 'domain/usecases/get_my_events.dart';
import 'domain/usecases/delete_event.dart';
import 'domain/usecases/get_event_attendees.dart';
import 'domain/usecases/check_in_attendee.dart' as event_checkin;

import 'domain/usecases/get_posts.dart';
import 'domain/usecases/create_post.dart';
import 'domain/usecases/like_post.dart';
import 'domain/usecases/unlike_post.dart';
import 'domain/usecases/repost_post.dart';
import 'domain/usecases/get_comments.dart';
import 'domain/usecases/create_comment.dart';
import 'domain/usecases/like_comment.dart';
import 'domain/usecases/unlike_comment.dart';
import 'domain/usecases/bookmark_post.dart';
import 'domain/usecases/unbookmark_post.dart';
import 'domain/usecases/get_bookmarked_posts.dart';
import 'domain/usecases/purchase_ticket.dart';
import 'domain/usecases/get_user_tickets.dart';
import 'domain/usecases/check_in_ticket.dart';
import 'domain/usecases/get_event_tickets.dart';
import 'domain/usecases/cancel_ticket.dart';
import 'domain/usecases/get_communities.dart';
import 'domain/usecases/get_joined_communities.dart';
import 'domain/usecases/join_community.dart';
import 'domain/usecases/leave_community.dart';
import 'domain/usecases/create_community.dart';
import 'domain/usecases/get_event_qna.dart';
import 'domain/usecases/ask_question.dart';
import 'domain/usecases/upvote_question.dart';
import 'domain/usecases/answer_question.dart';
import 'domain/usecases/delete_question.dart';
import 'domain/usecases/get_current_user.dart';
import 'domain/usecases/update_current_user.dart';
import 'domain/usecases/get_user_by_id.dart';
import 'domain/usecases/search_users.dart';
import 'domain/usecases/follow_user.dart';
import 'domain/usecases/unfollow_user.dart';
import 'domain/usecases/get_user_followers.dart';
import 'domain/usecases/get_user_following.dart';
import 'domain/usecases/get_ranked_feed.dart';

// Data
import 'data/datasources/event_local_datasource.dart';
import 'data/datasources/event_local_datasource_impl.dart';
import 'data/datasources/event_remote_datasource.dart';
import 'data/datasources/post_remote_datasource.dart';
import 'data/datasources/ticket_remote_datasource.dart';
import 'data/datasources/ticket_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/user_remote_datasource.dart';
import 'data/datasources/community_local_datasource.dart';
import 'data/datasources/community_local_datasource_impl.dart';
import 'data/datasources/community_remote_datasource.dart';
import 'data/datasources/qna_remote_datasource.dart';
import 'data/datasources/ranking_remote_datasource.dart';
import 'data/repositories/event_repository_impl.dart';
import 'data/repositories/post_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'data/repositories/community_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/qna_repository_impl.dart';
import 'data/repositories/ranking_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/payment_repository_impl.dart';
import 'domain/repositories/qna_repository.dart';
import 'data/services/analytics_service.dart';

// Presentation
import 'presentation/bloc/events/events_bloc.dart';
import 'presentation/bloc/user/user_bloc.dart';
import 'presentation/bloc/posts/posts_bloc.dart';
import 'presentation/bloc/tickets/tickets_bloc.dart';
import 'presentation/bloc/communities/communities_bloc.dart';
import 'presentation/bloc/qna/qna_bloc.dart';
import 'presentation/bloc/ranked_feed/ranked_feed_bloc.dart';
import 'presentation/bloc/notifications/notifications_bloc.dart';
import 'presentation/bloc/payment/payment_bloc.dart';
import 'presentation/bloc/my_events/my_events_bloc.dart';
import 'presentation/bloc/event_participants/event_participants_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core - External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton(() => secureStorage);

  // Core - HTTP Client
  sl.registerLazySingleton(() => DioClient());

  // Core - Services
  sl.registerLazySingleton(() => AuthService(sl(), sl()));
  sl.registerLazySingleton(() => GoogleAuthService());
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(() => ConnectivityService());

  // Initialize CacheStorageService (await initialization)
  final cacheStorage = CacheStorageService();
  await cacheStorage.init();
  sl.registerLazySingleton(() => cacheStorage);

  // Initialize Hive (required before any Hive box can be opened)
  await Hive.initFlutter();

  // Initialize LocationCacheService
  final locationCache = LocationCacheService();
  await locationCache.init();
  sl.registerLazySingleton(() => locationCache);

  sl.registerLazySingleton(() => AutoRefreshService(
    connectivityService: sl(),
    authService: sl(),
    authDataSource: sl(),
  ));

  // Register PaymentService for Midtrans integration
  final paymentService = PaymentService();
  await paymentService.initialize(
    clientKey: 'Mid-client-1aF77YEUN6blWKP1', // Sandbox key from .env
    merchantBaseUrl: 'https://app.sandbox.midtrans.com',
  );
  sl.registerLazySingleton(() => paymentService);

  // Analytics Service
  sl.registerLazySingleton(
    () => AnalyticsService(
      sl<DioClient>().dio,
      'https://api.anigmaa.com', // Production API base URL
    ),
  );

  // Features - Auth
  // Bloc - DioClient passed explicitly to avoid timing issues
  sl.registerLazySingleton(() => AuthBloc(sl(), sl(), sl()));

  // Features - Events
  // Bloc - SINGLETON to persist across tab navigation
  sl.registerLazySingleton(
    () => EventsBloc(
      getEvents: sl(),
      getEventsByCategory: sl(),
      createEvent: sl(),
      updateEvent: sl(),
      getEventById: sl(),
      toggleEventInterest: sl(),
      authService: sl(),
      getNearbyEvents: sl(),
      uploadImage: sl(),
    ),
  );

  // Features - User
  // Bloc - SINGLETON to persist across tab navigation
  sl.registerLazySingleton(
    () => UserBloc(
      authService: sl(),
      getCurrentUser: sl(),
      updateCurrentUser: sl(),
      getUserById: sl(),
      searchUsers: sl(),
      followUser: sl(),
      unfollowUser: sl(),
      getUserFollowers: sl(),
      getUserFollowing: sl(),
      getMyEvents: sl(),
      postRepository: sl(),
    ),
  );

  // Features - Posts
  // Bloc - SINGLETON to persist across tab navigation
  sl.registerLazySingleton(
    () => PostsBloc(
      getPosts: sl(),
      createPost: sl(),
      likePost: sl(),
      unlikePost: sl(),
      repostPost: sl(),
      getComments: sl(),
      createComment: sl(),
      likeComment: sl(),
      unlikeComment: sl(),
      bookmarkPost: sl(),
      unbookmarkPost: sl(),
      getBookmarkedPosts: sl(),
    ),
  );

  // Features - Tickets
  // Bloc
  sl.registerFactory(
    () => TicketsBloc(
      purchaseTicket: sl(),
      getUserTickets: sl(),
      checkInTicket: sl(),
      getEventTickets: sl(),
      cancelTicket: sl(),
    ),
  );

  // Features - Communities
  // Bloc - SINGLETON to persist across tab navigation
  sl.registerLazySingleton(
    () => CommunitiesBloc(
      getCommunities: sl(),
      getJoinedCommunities: sl(),
      joinCommunity: sl(),
      leaveCommunity: sl(),
      createCommunity: sl(),
    ),
  );

  // Features - QnA
  // Bloc
  sl.registerFactory(
    () => QnABloc(
      getEventQnA: sl(),
      askQuestion: sl(),
      upvoteQuestion: sl(),
      removeUpvote: sl(),
      answerQuestion: sl(),
      deleteQuestion: sl(),
    ),
  );

  // Features - Ranked Feed
  // Bloc
  sl.registerFactory(
    () => RankedFeedBloc(getRankedFeed: sl(), getCurrentUser: sl()),
  );

  // Features - Notifications
  // Bloc
  sl.registerFactory(() => NotificationsBloc(notificationRepository: sl()));

  // Features - Payment
  // Bloc
  sl.registerLazySingleton(() => PaymentBloc(paymentRepository: sl()));

  // Features - My Events
  // Bloc
  sl.registerFactory(() => MyEventsBloc(getMyEvents: sl(), deleteEvent: sl()));

  // Features - Event Participants
  // Bloc
  sl.registerFactory(
    () => EventParticipantsBloc(
      getEventAttendees: sl(),
      checkInAttendeeUseCase: event_checkin.CheckInAttendee(sl()),
    ),
  );

  // Use cases - Events
  sl.registerLazySingleton(() => GetEvents(sl()));
  sl.registerLazySingleton(() => GetEventsByCategory(sl()));
  sl.registerLazySingleton(() => GetNearbyEvents(sl())); // Added registration
  sl.registerLazySingleton(() => GetEventById(sl()));
  sl.registerLazySingleton(() => CreateEvent(sl()));
  sl.registerLazySingleton(() => UpdateEvent(sl()));
  sl.registerLazySingleton(() => ToggleEventInterest(sl()));
  sl.registerLazySingleton(() => GetMyEvents(sl()));
  sl.registerLazySingleton(() => DeleteEvent(sl()));
  sl.registerLazySingleton(() => GetEventAttendees(sl()));
  sl.registerLazySingleton(() => event_checkin.CheckInAttendee(sl()));
  sl.registerLazySingleton(() => UploadImage(sl()));

  // Use cases - Posts
  sl.registerLazySingleton(() => GetPosts(sl()));
  sl.registerLazySingleton(() => GetFeedPosts(sl()));
  sl.registerLazySingleton(() => CreatePost(sl()));
  sl.registerLazySingleton(() => LikePost(sl()));
  sl.registerLazySingleton(() => UnlikePost(sl()));
  sl.registerLazySingleton(() => RepostPost(sl()));
  sl.registerLazySingleton(() => GetComments(sl()));
  sl.registerLazySingleton(() => CreateComment(sl()));
  sl.registerLazySingleton(() => LikeComment(sl()));
  sl.registerLazySingleton(() => UnlikeComment(sl()));
  sl.registerLazySingleton(() => BookmarkPost(sl()));
  sl.registerLazySingleton(() => UnbookmarkPost(sl()));
  sl.registerLazySingleton(() => GetBookmarkedPosts(sl()));

  // Use cases - Tickets
  sl.registerLazySingleton(() => PurchaseTicket(sl()));
  sl.registerLazySingleton(() => GetUserTickets(sl()));
  sl.registerLazySingleton(() => CheckInTicket(sl()));
  sl.registerLazySingleton(() => GetEventTickets(sl()));
  sl.registerLazySingleton(() => CancelTicket(sl()));

  // Use cases - Communities
  sl.registerLazySingleton(() => GetCommunities(sl()));
  sl.registerLazySingleton(() => GetJoinedCommunities(sl()));
  sl.registerLazySingleton(() => JoinCommunity(sl()));
  sl.registerLazySingleton(() => LeaveCommunity(sl()));
  sl.registerLazySingleton(() => CreateCommunity(sl()));

  // Use cases - QnA
  sl.registerLazySingleton(() => GetEventQnA(sl()));
  sl.registerLazySingleton(() => AskQuestion(sl()));
  sl.registerLazySingleton(() => UpvoteQuestion(sl()));
  sl.registerLazySingleton(() => RemoveUpvote(sl()));
  sl.registerLazySingleton(() => AnswerQuestion(sl()));
  sl.registerLazySingleton(() => DeleteQuestion(sl()));

  // Use cases - Users
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => UpdateCurrentUser(sl()));
  sl.registerLazySingleton(() => GetUserById(sl()));
  sl.registerLazySingleton(() => SearchUsers(sl()));
  sl.registerLazySingleton(() => FollowUser(sl()));
  sl.registerLazySingleton(() => UnfollowUser(sl()));
  sl.registerLazySingleton(() => GetUserFollowers(sl()));
  sl.registerLazySingleton(() => GetUserFollowing(sl()));

  // Use cases - Ranking
  sl.registerLazySingleton(() => GetRankedFeed(sl()));

  // Data sources - Remote
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<TicketRemoteDataSource>(
    () => TicketRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<QnARemoteDataSource>(
    () => QnARemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<CommunityRemoteDataSource>(
    () => CommunityRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<RankingRemoteDataSource>(
    () => RankingRemoteDataSourceImpl(dioClient: sl()),
  );

  // Data sources - Local
  sl.registerLazySingleton<EventLocalDataSource>(
    () => EventLocalDataSourceImpl(sl<CacheStorageService>()),
  );

  sl.registerLazySingleton<TicketLocalDataSource>(
    () => TicketLocalDataSource(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<CommunityLocalDataSource>(
    () => CommunityLocalDataSourceImpl(sl<CacheStorageService>()),
  );

  // Repository - Events (Real repository with API)
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Repository - Posts
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(remoteDataSource: sl()),
  );

  // Repository - Tickets
  sl.registerLazySingleton<TicketRepository>(
    () => TicketRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      paymentService: sl(),
      eventRepository: sl(),
    ),
  );

  // Repository - Communities
  sl.registerLazySingleton<CommunityRepository>(
    () =>
        CommunityRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Repository - Users
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );

  // Repository - QnA
  sl.registerLazySingleton<QnARepository>(
    () => QnARepositoryImpl(remoteDataSource: sl()),
  );

  // Repository - Ranking
  sl.registerLazySingleton<RankingRepository>(
    () => RankingRepositoryImpl(remoteDataSource: sl()),
  );

  // Repository - Notifications
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );

  // Repository - Payment
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl(), sl()),
  );
}
