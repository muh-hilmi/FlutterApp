import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUserFollowing implements UseCase<List<User>, GetUserFollowingParams> {
  final UserRepository repository;

  GetUserFollowing(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(GetUserFollowingParams params) async {
    return await repository.getUserFollowing(
      params.userId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetUserFollowingParams extends Equatable {
  final String userId;
  final int limit;
  final int offset;

  const GetUserFollowingParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [userId, limit, offset];
}
