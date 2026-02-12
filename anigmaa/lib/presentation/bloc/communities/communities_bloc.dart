import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_communities.dart';
import '../../../domain/usecases/get_joined_communities.dart';
import '../../../domain/usecases/join_community.dart' as usecases;
import '../../../domain/usecases/leave_community.dart' as usecases;
import '../../../domain/usecases/create_community.dart';
import '../../../core/utils/network_resilience.dart';
import 'communities_event.dart';
import 'communities_state.dart';

/// Bloc for managing communities state
/// Now with network resilience - automatically retries on transient failures
class CommunitiesBloc extends Bloc<CommunitiesEvent, CommunitiesState>
    with NetworkResilienceBloc {
  final GetCommunities getCommunities;
  final GetJoinedCommunities getJoinedCommunities;
  final usecases.JoinCommunity joinCommunity;
  final usecases.LeaveCommunity leaveCommunity;
  final CreateCommunity createCommunity;

  CommunitiesBloc({
    required this.getCommunities,
    required this.getJoinedCommunities,
    required this.joinCommunity,
    required this.leaveCommunity,
    required this.createCommunity,
  }) : super(CommunitiesInitial()) {
    on<LoadCommunities>(_onLoadCommunities);
    on<LoadJoinedCommunities>(_onLoadJoinedCommunities);
    on<FilterCommunitiesByLocation>(_onFilterByLocation);
    on<FilterCommunitiesByCategory>(_onFilterByCategory);
    on<SearchCommunities>(_onSearchCommunities);
    on<JoinCommunity>(_onJoinCommunity);
    on<LeaveCommunity>(_onLeaveCommunity);
    on<CreateCommunityRequested>(_onCreateCommunity);
    on<RefreshCommunities>(_onRefreshCommunities);
  }

  Future<void> _onLoadCommunities(
    LoadCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    emit(CommunitiesLoading());

    // Use executeWithRetry for automatic retry on transient failures
    final result = await executeWithRetry(
      () => getCommunities(const GetCommunitiesParams()),
      maxRetries: 3,
    );

    result.fold(
      (failure) => emit(CommunitiesError(failure.message)),
      (response) {
        emit(CommunitiesLoaded(
          allCommunities: response.data,
          filteredCommunities: response.data,
          joinedCommunities: const [],
          selectedLocation: 'Jakarta',
        ));
      },
    );
  }

  Future<void> _onLoadJoinedCommunities(
    LoadJoinedCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    // TODO: Get actual user ID from UserBloc or auth
    final String userId = 'current_user_id';

    final result = await getJoinedCommunities(
      GetJoinedCommunitiesParams(userId: userId),
    );

    result.fold(
      (failure) => emit(CommunitiesError(failure.message)),
      (joined) {
        if (state is CommunitiesLoaded) {
          final currentState = state as CommunitiesLoaded;
          emit(currentState.copyWith(joinedCommunities: joined));
        }
      },
    );
  }

  void _onFilterByLocation(
    FilterCommunitiesByLocation event,
    Emitter<CommunitiesState> emit,
  ) {
    if (state is CommunitiesLoaded) {
      final currentState = state as CommunitiesLoaded;

      var filtered = currentState.allCommunities
          .where((c) => c.location == event.location)
          .toList();

      // Apply category filter if set
      if (currentState.selectedCategory != null) {
        filtered = filtered
            .where((c) => c.category == currentState.selectedCategory)
            .toList();
      }

      // Apply search filter if set
      if (currentState.searchQuery.isNotEmpty) {
        final query = currentState.searchQuery.toLowerCase();
        filtered = filtered.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.description.toLowerCase().contains(query);
        }).toList();
      }

      emit(currentState.copyWith(
        selectedLocation: event.location,
        filteredCommunities: filtered,
      ));
    }
  }

  void _onFilterByCategory(
    FilterCommunitiesByCategory event,
    Emitter<CommunitiesState> emit,
  ) {
    if (state is CommunitiesLoaded) {
      final currentState = state as CommunitiesLoaded;

      var filtered = currentState.allCommunities
          .where((c) => c.location == currentState.selectedLocation)
          .toList();

      // Apply category filter
      if (event.category != null) {
        filtered = filtered.where((c) => c.category == event.category).toList();
      }

      // Apply search filter if set
      if (currentState.searchQuery.isNotEmpty) {
        final query = currentState.searchQuery.toLowerCase();
        filtered = filtered.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.description.toLowerCase().contains(query);
        }).toList();
      }

      emit(currentState.copyWith(
        selectedCategory: event.category,
        filteredCommunities: filtered,
        clearCategory: event.category == null,
      ));
    }
  }

  void _onSearchCommunities(
    SearchCommunities event,
    Emitter<CommunitiesState> emit,
  ) {
    if (state is CommunitiesLoaded) {
      final currentState = state as CommunitiesLoaded;

      var filtered = currentState.allCommunities
          .where((c) => c.location == currentState.selectedLocation)
          .toList();

      // Apply category filter if set
      if (currentState.selectedCategory != null) {
        filtered = filtered
            .where((c) => c.category == currentState.selectedCategory)
            .toList();
      }

      // Apply search
      if (event.query.isNotEmpty) {
        final query = event.query.toLowerCase();
        filtered = filtered.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.description.toLowerCase().contains(query);
        }).toList();
      }

      emit(currentState.copyWith(
        searchQuery: event.query,
        filteredCommunities: filtered,
      ));
    }
  }

  Future<void> _onJoinCommunity(
    JoinCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    // TODO: Get actual user ID from UserBloc or auth
    final String userId = 'current_user_id';

    final result = await joinCommunity(
      usecases.JoinCommunityParams(
        communityId: event.communityId,
        userId: userId,
      ),
    );

    result.fold(
      (failure) => emit(CommunitiesError(failure.message)),
      (_) {
        if (state is CommunitiesLoaded) {
          final currentState = state as CommunitiesLoaded;
          final community = currentState.allCommunities.firstWhere(
            (c) => c.id == event.communityId,
          );
          final updatedJoined = [...currentState.joinedCommunities, community];

          emit(currentState.copyWith(joinedCommunities: updatedJoined));
        }
      },
    );
  }

  Future<void> _onLeaveCommunity(
    LeaveCommunity event,
    Emitter<CommunitiesState> emit,
  ) async {
    // TODO: Get actual user ID from UserBloc or auth
    final String userId = 'current_user_id';

    final result = await leaveCommunity(
      usecases.LeaveCommunityParams(
        communityId: event.communityId,
        userId: userId,
      ),
    );

    result.fold(
      (failure) => emit(CommunitiesError(failure.message)),
      (_) {
        if (state is CommunitiesLoaded) {
          final currentState = state as CommunitiesLoaded;
          final updatedJoined = currentState.joinedCommunities
              .where((c) => c.id != event.communityId)
              .toList();

          emit(currentState.copyWith(joinedCommunities: updatedJoined));
        }
      },
    );
  }

  Future<void> _onCreateCommunity(
    CreateCommunityRequested event,
    Emitter<CommunitiesState> emit,
  ) async {
    final result = await createCommunity(
      CreateCommunityParams(community: event.community),
    );

    result.fold(
      (failure) => emit(CommunitiesError(failure.message)),
      (createdCommunity) {
        if (state is CommunitiesLoaded) {
          final currentState = state as CommunitiesLoaded;
          final updatedAll = [createdCommunity, ...currentState.allCommunities];
          final updatedJoined = [createdCommunity, ...currentState.joinedCommunities];

          // Re-apply current filters
          var filtered = updatedAll
              .where((c) => c.location == currentState.selectedLocation)
              .toList();

          if (currentState.selectedCategory != null) {
            filtered = filtered
                .where((c) => c.category == currentState.selectedCategory)
                .toList();
          }

          if (currentState.searchQuery.isNotEmpty) {
            final query = currentState.searchQuery.toLowerCase();
            filtered = filtered.where((c) {
              return c.name.toLowerCase().contains(query) ||
                  c.description.toLowerCase().contains(query);
            }).toList();
          }

          emit(CommunitiesLoaded(
            allCommunities: updatedAll,
            filteredCommunities: filtered,
            joinedCommunities: updatedJoined,
            selectedLocation: currentState.selectedLocation,
            selectedCategory: currentState.selectedCategory,
            searchQuery: currentState.searchQuery,
          ));
        } else {
          add(LoadCommunities());
        }
      },
    );
  }

  Future<void> _onRefreshCommunities(
    RefreshCommunities event,
    Emitter<CommunitiesState> emit,
  ) async {
    add(LoadCommunities());
    add(LoadJoinedCommunities());
  }
}
