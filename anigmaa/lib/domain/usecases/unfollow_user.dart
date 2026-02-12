import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/user_repository.dart';

class UnfollowUser implements UseCase<void, UnfollowUserParams> {
  final UserRepository repository;

  UnfollowUser(this.repository);

  @override
  Future<Either<Failure, void>> call(UnfollowUserParams params) async {
    return await repository.unfollowUser(params.userId);
  }
}

class UnfollowUserParams extends Equatable {
  final String userId;

  const UnfollowUserParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
