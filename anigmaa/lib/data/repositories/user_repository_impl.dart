import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get current user: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final userModel = await remoteDataSource.getUserById(userId);
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get user: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> updateCurrentUser(Map<String, dynamic> userData) async {
    try {
      final userModel = await remoteDataSource.updateCurrentUser(userData);
      return Right(userModel);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to update user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      await remoteDataSource.updateUserSettings(settings);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to update settings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<User>>> searchUsers(String query, {int limit = 20, int offset = 0}) async {
    try {
      final userModels = await remoteDataSource.searchUsers(query, limit: limit, offset: offset);
      return Right(userModels);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to search users: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> followUser(String userId) async {
    try {
      await remoteDataSource.followUser(userId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to follow user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unfollowUser(String userId) async {
    try {
      await remoteDataSource.unfollowUser(userId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to unfollow user: $e'));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getUserFollowers(String userId, {int limit = 20, int offset = 0}) async {
    try {
      final userModels = await remoteDataSource.getUserFollowers(userId, limit: limit, offset: offset);
      return Right(userModels);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get followers: $e'));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getUserFollowing(String userId, {int limit = 20, int offset = 0}) async {
    try {
      final userModels = await remoteDataSource.getUserFollowing(userId, limit: limit, offset: offset);
      return Right(userModels);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get following: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserStats(String userId) async {
    try {
      final stats = await remoteDataSource.getUserStats(userId);
      return Right(stats);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get user stats: $e'));
    }
  }
}
