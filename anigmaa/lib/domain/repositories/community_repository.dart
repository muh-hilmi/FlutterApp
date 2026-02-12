import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../entities/community.dart';
import '../entities/community_category.dart';

abstract class CommunityRepository {
  Future<Either<Failure, PaginatedResponse<Community>>> getCommunities({int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResponse<Community>>> getCommunitiesByLocation(String location, {int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResponse<Community>>> getCommunitiesByCategory(CommunityCategory category, {int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResponse<Community>>> getJoinedCommunities(String userId, {int limit = 20, int offset = 0});
  Future<Either<Failure, Community>> getCommunityById(String id);
  Future<Either<Failure, Community>> createCommunity(Community community);
  Future<Either<Failure, Community>> updateCommunity(Community community);
  Future<Either<Failure, void>> deleteCommunity(String id);
  Future<Either<Failure, void>> joinCommunity(String communityId, String userId);
  Future<Either<Failure, void>> leaveCommunity(String communityId, String userId);
}
