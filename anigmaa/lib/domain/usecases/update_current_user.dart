import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class UpdateCurrentUser implements UseCase<User, UpdateCurrentUserParams> {
  final UserRepository repository;

  UpdateCurrentUser(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateCurrentUserParams params) async {
    return await repository.updateCurrentUser(params.userData);
  }
}

class UpdateCurrentUserParams {
  final Map<String, dynamic> userData;

  const UpdateCurrentUserParams({required this.userData});
}
