import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class SearchUsers implements UseCase<List<User>, SearchUsersParams> {
  final UserRepository repository;

  SearchUsers(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(SearchUsersParams params) async {
    return await repository.searchUsers(
      params.query,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class SearchUsersParams extends Equatable {
  final String query;
  final int limit;
  final int offset;

  const SearchUsersParams({
    required this.query,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [query, limit, offset];
}
