import 'package:equatable/equatable.dart';
import '../../../domain/entities/community.dart';
import '../../../domain/entities/community_category.dart';

abstract class CommunitiesEvent extends Equatable {
  const CommunitiesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCommunities extends CommunitiesEvent {}

class LoadJoinedCommunities extends CommunitiesEvent {}

class FilterCommunitiesByLocation extends CommunitiesEvent {
  final String location;

  const FilterCommunitiesByLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class FilterCommunitiesByCategory extends CommunitiesEvent {
  final CommunityCategory? category;

  const FilterCommunitiesByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchCommunities extends CommunitiesEvent {
  final String query;

  const SearchCommunities(this.query);

  @override
  List<Object?> get props => [query];
}

class JoinCommunity extends CommunitiesEvent {
  final String communityId;

  const JoinCommunity(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class LeaveCommunity extends CommunitiesEvent {
  final String communityId;

  const LeaveCommunity(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class CreateCommunityRequested extends CommunitiesEvent {
  final Community community;

  const CreateCommunityRequested(this.community);

  @override
  List<Object?> get props => [community];
}

class RefreshCommunities extends CommunitiesEvent {}
