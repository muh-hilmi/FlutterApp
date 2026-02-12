import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUserFollowers implements UseCase<List<User>, GetUserFollowersParams> {
  final UserRepository repository;

  GetUserFollowers(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(GetUserFollowersParams params) async {
    return await repository.getUserFollowers(
      params.userId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetUserFollowersParams extends Equatable {
  final String userId;
  final int limit;
  final int offset;

  const GetUserFollowersParams({
    required this.userId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [userId, limit, offset];
}
