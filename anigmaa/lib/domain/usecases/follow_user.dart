import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/user_repository.dart';

class FollowUser implements UseCase<void, FollowUserParams> {
  final UserRepository repository;

  FollowUser(this.repository);

  @override
  Future<Either<Failure, void>> call(FollowUserParams params) async {
    return await repository.followUser(params.userId);
  }
}

class FollowUserParams extends Equatable {
  final String userId;

  const FollowUserParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
