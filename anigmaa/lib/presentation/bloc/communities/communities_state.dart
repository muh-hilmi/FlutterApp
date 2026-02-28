import 'package:equatable/equatable.dart';
import '../../../domain/entities/community.dart';
import '../../../domain/entities/community_category.dart';

abstract class CommunitiesState extends Equatable {
  const CommunitiesState();

  @override
  List<Object?> get props => [];
}

class CommunitiesInitial extends CommunitiesState {}

class CommunitiesLoading extends CommunitiesState {}

class CommunitiesLoaded extends CommunitiesState {
  final List<Community> allCommunities;
  final List<Community> filteredCommunities;
  final List<Community> joinedCommunities;
  final String selectedLocation;
  final CommunityCategory? selectedCategory;
  final String searchQuery;

  const CommunitiesLoaded({
    required this.allCommunities,
    required this.filteredCommunities,
    required this.joinedCommunities,
    required this.selectedLocation,
    this.selectedCategory,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
        allCommunities,
        filteredCommunities,
        joinedCommunities,
        selectedLocation,
        selectedCategory,
        searchQuery,
      ];

  CommunitiesLoaded copyWith({
    List<Community>? allCommunities,
    List<Community>? filteredCommunities,
    List<Community>? joinedCommunities,
    String? selectedLocation,
    CommunityCategory? selectedCategory,
    String? searchQuery,
    bool clearCategory = false,
  }) {
    return CommunitiesLoaded(
      allCommunities: allCommunities ?? this.allCommunities,
      filteredCommunities: filteredCommunities ?? this.filteredCommunities,
      joinedCommunities: joinedCommunities ?? this.joinedCommunities,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CommunitiesError extends CommunitiesState {
  final String message;

  const CommunitiesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Offline state - shows cached communities when network is unavailable
class CommunitiesOffline extends CommunitiesState {
  final List<Community> cachedCommunities;
  final String? message;

  const CommunitiesOffline({
    required this.cachedCommunities,
    this.message = 'Offline — menampilkan data terakhir',
  });

  @override
  List<Object?> get props => [cachedCommunities, message];
}

class CommunityCreated extends CommunitiesState {
  final Community community;

  const CommunityCreated(this.community);

  @override
  List<Object?> get props => [community];
}

class CommunityJoined extends CommunitiesState {
  final String communityId;

  const CommunityJoined(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class CommunityLeft extends CommunitiesState {
  final String communityId;

  const CommunityLeft(this.communityId);

  @override
  List<Object?> get props => [communityId];
}
