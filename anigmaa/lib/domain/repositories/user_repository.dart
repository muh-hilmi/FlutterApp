import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  /// Get current authenticated user
  Future<Either<Failure, User>> getCurrentUser();

  /// Get user by ID
  Future<Either<Failure, User>> getUserById(String userId);

  /// Update current user profile
  Future<Either<Failure, User>> updateCurrentUser(Map<String, dynamic> userData);

  /// Update user settings
  Future<Either<Failure, void>> updateUserSettings(Map<String, dynamic> settings);

  /// Search users
  Future<Either<Failure, List<User>>> searchUsers(String query, {int limit = 20, int offset = 0});

  /// Follow a user
  Future<Either<Failure, void>> followUser(String userId);

  /// Unfollow a user
  Future<Either<Failure, void>> unfollowUser(String userId);

  /// Get user's followers
  Future<Either<Failure, List<User>>> getUserFollowers(String userId, {int limit = 20, int offset = 0});

  /// Get user's following
  Future<Either<Failure, List<User>>> getUserFollowing(String userId, {int limit = 20, int offset = 0});

  /// Get user statistics
  Future<Either<Failure, Map<String, dynamic>>> getUserStats(String userId);
}
