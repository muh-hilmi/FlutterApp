import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_category.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_local_datasource.dart';
import '../datasources/community_remote_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;
  final CommunityLocalDataSource localDataSource;

  CommunityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResponse<Community>>> getCommunities({int limit = 20, int offset = 0}) async {
    try {
      // Fetch from API
      final communityModels = await remoteDataSource.getCommunities();
      final communities = communityModels.map((model) => model.toEntity()).toList();

      // Cache locally
      await localDataSource.cacheCommunities(communities);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: communities, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      // If API fails, try to get from cache
      try {
        final communities = await localDataSource.getCommunities();
        final meta = PaginationMeta.empty();
        return Right(PaginatedResponse(data: communities, meta: meta));
      } catch (cacheError) {
        return Left(ServerFailure('Failed to get communities: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Community>>> getCommunitiesByLocation(String location, {int limit = 20, int offset = 0}) async {
    try {
      // Search communities by location using search parameter
      final communityModels = await remoteDataSource.getCommunities(search: location);
      final communities = communityModels.map((model) => model.toEntity()).toList();

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: communities, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get communities by location: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Community>>> getCommunitiesByCategory(CommunityCategory category, {int limit = 20, int offset = 0}) async {
    try {
      // Get all communities and filter by category
      final communityModels = await remoteDataSource.getCommunities();
      final communities = communityModels
          .map((model) => model.toEntity())
          .where((community) => community.category == category)
          .toList();

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: communities, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get communities by category: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Community>>> getJoinedCommunities(String userId, {int limit = 20, int offset = 0}) async {
    try {
      // Get user's joined communities from API
      final communityModels = await remoteDataSource.getMyCommunities();
      final communities = communityModels.map((model) => model.toEntity()).toList();

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: communities, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get joined communities: $e'));
    }
  }

  @override
  Future<Either<Failure, Community>> getCommunityById(String id) async {
    try {
      // Fetch from API
      final communityModel = await remoteDataSource.getCommunityById(id);
      final community = communityModel.toEntity();

      // Cache locally
      await localDataSource.cacheCommunity(community);

      return Right(community);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      // If API fails, try to get from cache
      try {
        final community = await localDataSource.getCommunityById(id);
        if (community == null) {
          return Left(NotFoundFailure('Community not found'));
        }
        return Right(community);
      } catch (cacheError) {
        return Left(ServerFailure('Failed to get community: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, Community>> createCommunity(Community community) async {
    try {
      // Create via API
      final communityData = {
        'name': community.name,
        'description': community.description,
        'avatar_url': community.icon,
        'cover_url': community.coverImage,
        'privacy': community.isPublic ? 'public' : 'private',
      };

      final communityModel = await remoteDataSource.createCommunity(communityData);
      final createdCommunity = communityModel.toEntity();

      // Cache locally
      await localDataSource.cacheCommunity(createdCommunity);

      return Right(createdCommunity);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to create community: $e'));
    }
  }

  @override
  Future<Either<Failure, Community>> updateCommunity(Community community) async {
    try {
      // Update via API
      final communityData = {
        'name': community.name,
        'description': community.description,
        'avatar_url': community.icon,
        'cover_url': community.coverImage,
        'privacy': community.isPublic ? 'public' : 'private',
      };

      final communityModel = await remoteDataSource.updateCommunity(community.id, communityData);
      final updatedCommunity = communityModel.toEntity();

      // Update cache
      await localDataSource.cacheCommunity(updatedCommunity);

      return Right(updatedCommunity);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to update community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCommunity(String id) async {
    try {
      // Delete via API
      await remoteDataSource.deleteCommunity(id);

      // Delete from cache
      await localDataSource.deleteCommunity(id);

      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to delete community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinCommunity(String communityId, String userId) async {
    try {
      // Join via API
      await remoteDataSource.joinCommunity(communityId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to join community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveCommunity(String communityId, String userId) async {
    try {
      // Leave via API
      await remoteDataSource.leaveCommunity(communityId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to leave community: $e'));
    }
  }
}
