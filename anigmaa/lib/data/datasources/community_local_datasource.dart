import '../../domain/entities/community.dart';
import '../../domain/entities/community_category.dart';

abstract class CommunityLocalDataSource {
  Future<List<Community>> getCommunities();
  Future<List<Community>> getCommunitiesByLocation(String location);
  Future<List<Community>> getCommunitiesByCategory(CommunityCategory category);
  Future<List<Community>> getJoinedCommunities(String userId);
  Future<Community?> getCommunityById(String id);
  Future<void> cacheCommunities(List<Community> communities);
  Future<void> cacheCommunity(Community community);
  Future<void> deleteCommunity(String id);
}

