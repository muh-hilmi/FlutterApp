import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/event.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/network_resilience.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/get_user_by_id.dart';
import '../../../domain/usecases/search_users.dart';
import '../../../domain/usecases/follow_user.dart';
import '../../../domain/usecases/unfollow_user.dart';
import '../../../domain/usecases/get_user_followers.dart';
import '../../../domain/usecases/get_user_following.dart';
import '../../../domain/usecases/update_current_user.dart';
import '../../../domain/usecases/get_my_events.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../../core/errors/failures.dart';
import 'user_event.dart';
import 'user_state.dart';

/// Bloc for managing user state and interactions
/// Handles profile management, social features, and user data operations
///
/// Now with network resilience - automatically retries on transient failures
class UserBloc extends Bloc<UserEvent, UserState> with NetworkResilienceBloc {
  final AuthService authService;
  final GetCurrentUser? getCurrentUser;
  final UpdateCurrentUser? updateCurrentUser;
  final GetUserById? getUserById;
  final SearchUsers? searchUsers;
  final FollowUser? followUser;
  final UnfollowUser? unfollowUser;
  final GetUserFollowers? getUserFollowers;
  final GetUserFollowing? getUserFollowing;
  final GetMyEvents? getMyEvents;
  final PostRepository? postRepository;
  final AppLogger _logger = AppLogger();

  UserBloc({
    required this.authService,
    this.getCurrentUser,
    this.updateCurrentUser,
    this.getUserById,
    this.searchUsers,
    this.followUser,
    this.unfollowUser,
    this.getUserFollowers,
    this.getUserFollowing,
    this.getMyEvents,
    this.postRepository,
  }) : super(UserInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<LoadUserById>(_onLoadUserById);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<TogglePremium>(_onTogglePremium);
    on<AddInterest>(_onAddInterest);
    on<RemoveInterest>(_onRemoveInterest);
    on<SearchUsersEvent>(_onSearchUsers);
    on<FollowUserEvent>(_onFollowUser);
    on<UnfollowUserEvent>(_onUnfollowUser);
    on<LoadFollowersEvent>(_onLoadFollowers);
    on<LoadFollowingEvent>(_onLoadFollowing);
    on<LoadUserPostsEvent>(_onLoadUserPosts);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      // Try to use API if available - now with automatic retry
      if (getCurrentUser != null) {
        _logger.info('Calling getCurrentUser API with retry...');

        final result = await executeWithRetry(
          () => getCurrentUser!(NoParams()),
          maxRetries: 3,
        );

        // Use fold to extract result, but store in variables instead of emitting
        late User user;
        Failure? failure;

        result.fold(
          (f) => failure = f,
          (u) => user = u,
        );

        // Handle failure case
        if (failure != null) {
          // Don't fallback to mock if it's 401 Unauthorized
          // Let AuthInterceptor handle the redirect to login
          if (failure is AuthenticationFailure ||
              failure is UnauthorizedFailure) {
            _logger.warning('🔒 Unauthorized (401) - not using mock data');
            emit(UserError(_getUserFriendlyError(failure!.message)));
            return;
          }

          // For network/timeout errors after retries, show user-friendly message
          // but don't fall back to mock data - that's confusing
          if (failure is NetworkFailure || failure is TimeoutFailure) {
            _logger.error('API failed after retries: ${failure!.message}');
            emit(UserError(_getUserFriendlyError(failure!.message)));
            return;
          }

          // For server errors, show message
          _logger.error('API failed: ${failure!.message}');
          emit(UserError(_getUserFriendlyError(failure!.message)));
          return;
        }

        // Success case - now we can use await properly
        _logger.info(
          'API success! User ID: ${user.id}, Name: ${user.name}, Email: ${user.email}',
        );

        // Get actual events count from GetMyEvents
        int actualEventsHosted = user.stats.eventsCreated;
        List<Event> actualEventsList = const []; // Store actual events for profile tab
        if (getMyEvents != null) {
          final eventsResult = await getMyEvents!(const GetMyEventsParams());
          eventsResult.fold(
            (f) {
              _logger.warning('Failed to get actual events count: ${f.message}');
              // Fallback to stats from user object
            },
            (events) {
              // actualEventsHosted = ALL events (for tab bar)
              actualEventsHosted = events.length;
              // activeEventsCount = active only (for header)
              final activeEventsCount = events.where((e) => e.isActive).length;
              actualEventsList = events; // Store all events for profile tab
              _logger.info('Total events: $actualEventsHosted, Active events: $activeEventsCount');
            },
          );
        }

        // Calculate active events count for header
        final activeEventsCount = actualEventsList.isEmpty
            ? 0
            : actualEventsList.where((e) => e.isActive).length;

        emit(
          UserLoaded(
            user: user,
            eventsHosted: actualEventsHosted,
            activeEventsCount: activeEventsCount,
            eventsAttended: user.stats.eventsAttended,
            connections: user.stats.followersCount,
            postsCount:
                0, // REDNOTE: Get from actual posts data via PostRepository
            totalInvitedAttendees:
                0, // REDNOTE: Calculate from events attendees data
            userEvents: actualEventsList, // Added: actual events for profile
          ),
        );
      } else {
        // No API available, use mock data
        _logger.warning(
          'getCurrentUser use case not available, using mock data',
        );
        _loadMockUserProfile(emit);
      }
    } catch (e) {
      _logger.error('Exception caught', e);
      emit(UserError('Gagal memuat profil. Coba lagi ya! 🔄'));
    }
  }

  // Helper function to convert technical errors to user-friendly messages
  String _getUserFriendlyError(String technicalError) {
    if (technicalError.contains('network') ||
        technicalError.contains('connection')) {
      return 'Koneksi internet bermasalah. Cek koneksi kamu ya! 📡';
    } else if (technicalError.contains('timeout')) {
      return 'Server lagi lelet nih. Coba lagi yuk! ⏱️';
    } else if (technicalError.contains('404') ||
        technicalError.contains('not found')) {
      return 'Data ga ketemu. Mungkin udah dihapus 🤔';
    } else if (technicalError.contains('500') ||
        technicalError.contains('server')) {
      return 'Server lagi bermasalah. Tunggu sebentar ya! 🔧';
    } else {
      return 'Ada kendala nih. Coba lagi ya! 😅';
    }
  }

  void _loadMockUserProfile(Emitter<UserState> emit) {
    // Get user from auth service
    final email = authService.userEmail ?? 'user@flyerr.com';
    final name = authService.userName ?? 'flyerr User';

    // Mock user data - MINIMAL DATA (no dummy bio/avatar)
    final user = User(
      id: '1',
      name: name,
      email: email,
      avatar: null, // No dummy avatar
      bio: null, // No dummy bio
      interests: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      lastLoginAt: DateTime.now(),
      settings: const UserSettings(),
      stats: const UserStats(
        eventsAttended: 0,
        eventsCreated: 0,
        followersCount: 0, // Fixed: no dummy follower count
        followingCount: 0,
        reviewsGiven: 0,
        averageRating: 0.0,
      ),
      privacy: const UserPrivacy(),
      isVerified: false,
      isEmailVerified: true,
    );

    emit(
      UserLoaded(
        user: user,
        eventsHosted: user.stats.eventsCreated,
        eventsAttended: user.stats.eventsAttended,
        connections: user.stats.followersCount,
        postsCount: 0,
        totalInvitedAttendees: 0,
      ),
    );
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserState> emit,
  ) async {
    if (state is! UserLoaded) return;

    final currentState = state as UserLoaded;
    emit(UserLoading());

    try {
      // Prepare update data - only include fields that are provided
      final Map<String, dynamic> updateData = {};
      if (event.name != null) {
        updateData['name'] = event.name;
      }
      if (event.bio != null) {
        updateData['bio'] = event.bio;
      }
      if (event.avatar != null) {
        updateData['avatar'] = event.avatar;
      }
      if (event.interests != null) {
        updateData['interests'] = event.interests;
      }
      if (event.phone != null && event.phone!.isNotEmpty) {
        // Strip all non-numeric characters for backend validation
        final cleanPhone = event.phone!.replaceAll(RegExp(r'[^\d]'), '');
        updateData['phone'] = cleanPhone;
      }
      if (event.dateOfBirth != null) {
        updateData['date_of_birth'] = event.dateOfBirth!.toIso8601String();
      }
      if (event.gender != null) {
        updateData['gender'] = event.gender;
      }
      if (event.location != null) {
        updateData['location'] = event.location;
      }

      _logger.info('Updating user profile');

      // Call API to update user
      if (updateCurrentUser != null) {
        final result = await updateCurrentUser!(
          UpdateCurrentUserParams(userData: updateData),
        );

        result.fold(
          (failure) {
            _logger.error('Update failed: ${failure.message}');
            emit(UserError(_getUserFriendlyError(failure.message)));
            // Restore previous state
            emit(currentState);
          },
          (updatedUser) {
            _logger.info('Update successful: ${updatedUser.name}');
            emit(currentState.copyWith(user: updatedUser));
          },
        );
      } else {
        // Fallback to local update if API not available
        _logger.warning('API not available, doing local update');
        final updatedUser = currentState.user.copyWith(
          name: event.name ?? currentState.user.name,
          bio: event.bio ?? currentState.user.bio,
          avatar: event.avatar ?? currentState.user.avatar,
          interests: event.interests ?? currentState.user.interests,
          phone: event.phone ?? currentState.user.phone,
          dateOfBirth: event.dateOfBirth ?? currentState.user.dateOfBirth,
          gender: event.gender ?? currentState.user.gender,
          location: event.location ?? currentState.user.location,
        );
        emit(currentState.copyWith(user: updatedUser));
      }
    } catch (e) {
      _logger.error('Update error', e);
      emit(UserError('Gagal update profil. Coba lagi ya! 🔄'));
      // Restore previous state
      emit(currentState);
    }
  }

  Future<void> _onTogglePremium(
    TogglePremium event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;

      // For now, just toggle isVerified as "premium" indicator
      final updatedUser = currentState.user.copyWith(
        isVerified: !currentState.user.isVerified,
      );

      emit(currentState.copyWith(user: updatedUser));
    }
  }

  Future<void> _onAddInterest(
    AddInterest event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;

      if (!currentState.user.interests.contains(event.interest)) {
        final updatedInterests = [
          ...currentState.user.interests,
          event.interest,
        ];
        final updatedUser = currentState.user.copyWith(
          interests: updatedInterests,
        );

        emit(currentState.copyWith(user: updatedUser));
      }
    }
  }

  Future<void> _onRemoveInterest(
    RemoveInterest event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;

      final updatedInterests = currentState.user.interests
          .where((interest) => interest != event.interest)
          .toList();

      final updatedUser = currentState.user.copyWith(
        interests: updatedInterests,
      );

      emit(currentState.copyWith(user: updatedUser));
    }
  }

  Future<void> _onLoadUserById(
    LoadUserById event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      if (getUserById != null) {
        final result = await getUserById!(
          GetUserByIdParams(userId: event.userId),
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('Request timeout. Cek koneksi internet kamu! 📡'),
        );

        // Use fold to extract result
        late User user;
        Failure? failure;

        result.fold(
          (f) => failure = f,
          (u) => user = u,
        );

        // Handle failure case
        if (failure != null) {
          emit(UserError(_getUserFriendlyError(failure.toString())));
          return;
        }

        // Get actual events count if loading own profile
        int actualEventsHosted = user.stats.eventsCreated;
        List<Event> actualEventsList = const []; // Store actual events for profile tab
        final currentUserId = authService.userId;
        if (event.userId == currentUserId && getMyEvents != null) {
          final eventsResult = await getMyEvents!(const GetMyEventsParams()).timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Request timeout. Cek koneksi internet kamu! 📡'),
          );
          eventsResult.fold(
            (f) {
              _logger.warning('Failed to get actual events count: ${f.message}');
              // Fallback to stats from user object
            },
            (events) {
              // actualEventsHosted = ALL events (for tab bar)
              actualEventsHosted = events.length;
              actualEventsList = events; // Store all events for profile tab
              final activeEventsCount = events.where((e) => e.isActive).length;
              _logger.info('Total events for own profile: $actualEventsHosted, Active: $activeEventsCount');
            },
          );
        }

        // Calculate active events count for header
        final activeEventsCount = actualEventsList.isEmpty
            ? 0
            : actualEventsList.where((e) => e.isActive).length;

        emit(
          UserLoaded(
            user: user,
            eventsHosted: actualEventsHosted,
            activeEventsCount: activeEventsCount,
            eventsAttended: user.stats.eventsAttended,
            connections: user.stats.followersCount,
            postsCount:
                0, // REDNOTE: Get from actual posts data via PostRepository
            totalInvitedAttendees:
                0, // REDNOTE: Calculate from events attendees data
            userEvents: actualEventsList, // Added: actual events for profile
          ),
        );

        // Trigger posts loading AFTER UserLoaded state is emitted
        if (postRepository != null) {
          add(LoadUserPostsEvent(event.userId));
        }
      } else {
        emit(const UserError('Fitur ini belum tersedia. Maaf ya! 🙏'));
      }
    } catch (e) {
      emit(UserError('Gagal memuat profil user. Coba lagi ya! 🔄'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    if (searchUsers == null) {
      emit(const UsersSearchError('Search feature not available'));
      return;
    }

    emit(UsersSearchLoading());

    try {
      final result = await searchUsers!(SearchUsersParams(query: event.query));

      result.fold(
        (failure) => emit(UsersSearchError(failure.toString())),
        (users) => emit(UsersSearchLoaded(users)),
      );
    } catch (e) {
      emit(UsersSearchError('Failed to search users: $e'));
    }
  }

  Future<void> _onFollowUser(
    FollowUserEvent event,
    Emitter<UserState> emit,
  ) async {
    if (followUser == null) {
      emit(
        const UserError(
          'Fitur follow belum tersedia. Tunggu update selanjutnya ya! 🚀',
        ),
      );
      return;
    }

    // Get current state to update optimistically
    final currentState = state;

    try {
      final result = await followUser!(FollowUserParams(userId: event.userId));

      result.fold(
        (failure) => emit(UserError(_getUserFriendlyError(failure.toString()))),
        (_) {
          // Optimistically update the UI
          if (currentState is UserLoaded) {
            final updatedStats = currentState.user.stats.copyWith(
              followersCount: currentState.user.stats.followersCount + 1,
            );
            final updatedUser = currentState.user.copyWith(
              isFollowing: true,
              stats: updatedStats,
            );

            emit(
              currentState.copyWith(
                user: updatedUser,
                connections: updatedStats.followersCount,
              ),
            );
          } else {
            emit(const UserActionSuccess('Successfully followed user'));
          }
        },
      );
    } catch (e) {
      emit(UserError('Gagal follow user. Coba lagi ya! 🔄'));
    }
  }

  Future<void> _onUnfollowUser(
    UnfollowUserEvent event,
    Emitter<UserState> emit,
  ) async {
    if (unfollowUser == null) {
      emit(
        const UserError(
          'Fitur unfollow belum tersedia. Tunggu update selanjutnya ya! 🚀',
        ),
      );
      return;
    }

    // Get current state to update optimistically
    final currentState = state;

    try {
      final result = await unfollowUser!(
        UnfollowUserParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(UserError(_getUserFriendlyError(failure.toString()))),
        (_) {
          // Optimistically update the UI
          if (currentState is UserLoaded) {
            final updatedStats = currentState.user.stats.copyWith(
              followersCount: currentState.user.stats.followersCount - 1,
            );
            final updatedUser = currentState.user.copyWith(
              isFollowing: false,
              stats: updatedStats,
            );

            emit(
              currentState.copyWith(
                user: updatedUser,
                connections: updatedStats.followersCount,
              ),
            );
          } else {
            emit(const UserActionSuccess('Successfully unfollowed user'));
          }
        },
      );
    } catch (e) {
      emit(UserError('Gagal unfollow user. Coba lagi ya! 🔄'));
    }
  }

  Future<void> _onLoadFollowers(
    LoadFollowersEvent event,
    Emitter<UserState> emit,
  ) async {
    if (getUserFollowers == null) {
      emit(
        const UserError(
          'Fitur followers belum tersedia. Tunggu update selanjutnya ya! 🚀',
        ),
      );
      return;
    }

    emit(FollowersLoading());

    try {
      final result = await getUserFollowers!(
        GetUserFollowersParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(UserError(_getUserFriendlyError(failure.toString()))),
        (followers) => emit(FollowersLoaded(followers)),
      );
    } catch (e) {
      emit(UserError('Gagal memuat followers. Coba lagi ya! 🔄'));
    }
  }

  Future<void> _onLoadFollowing(
    LoadFollowingEvent event,
    Emitter<UserState> emit,
  ) async {
    if (getUserFollowing == null) {
      emit(
        const UserError(
          'Fitur following belum tersedia. Tunggu update selanjutnya ya! 🚀',
        ),
      );
      return;
    }

    emit(FollowingLoading());

    try {
      final result = await getUserFollowing!(
        GetUserFollowingParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(UserError(_getUserFriendlyError(failure.toString()))),
        (following) => emit(FollowingLoaded(following)),
      );
    } catch (e) {
      emit(UserError('Gagal memuat following. Coba lagi ya! 🔄'));
    }
  }

  Future<void> _onLoadUserPosts(
    LoadUserPostsEvent event,
    Emitter<UserState> emit,
  ) async {
    // Load posts independently - don't require UserLoaded state
    if (postRepository == null) {
      _logger.warning('[UserBloc] PostRepository not available');
      return;
    }

    try {
      _logger.info('[UserBloc] Loading posts for user ${event.userId}...');
      final result = await postRepository!.getUserPosts(
        event.userId,
        limit: 50,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Request timeout. Cek koneksi internet kamu! 📡'),
      );

      result.fold(
        (failure) {
          _logger.error('[UserBloc] Failed to load user posts: ${failure.message}');
          // If state is UserLoaded, update it with error status
          if (state is UserLoaded) {
            final currentState = state as UserLoaded;
            emit(currentState.copyWith(userPosts: [], postsCount: 0));
          }
        },
        (paginatedPosts) {
          _logger.info(
            '[UserBloc] Loaded ${paginatedPosts.data.length} posts for user ${event.userId}',
          );
          // If state is UserLoaded, merge the posts into it
          if (state is UserLoaded) {
            final currentState = state as UserLoaded;
            emit(
              currentState.copyWith(
                userPosts: paginatedPosts.data,
                postsCount: paginatedPosts.data.length,
              ),
            );
          } else {
            // If not in UserLoaded state yet, store posts for later
            // When UserLoaded happens, it will pick up these posts
            _logger.info('[UserBloc] Posts loaded but state not UserLoaded yet - will be picked up later');
          }
        },
      );
    } catch (e) {
      _logger.error('[UserBloc] Exception loading user posts: $e');
    }
  }
}
