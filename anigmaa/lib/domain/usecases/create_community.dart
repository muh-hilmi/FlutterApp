import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../repositories/community_repository.dart';

class CreateCommunity implements UseCase<Community, CreateCommunityParams> {
  final CommunityRepository repository;

  CreateCommunity(this.repository);

  @override
  Future<Either<Failure, Community>> call(CreateCommunityParams params) async {
    return await repository.createCommunity(params.community);
  }
}

class CreateCommunityParams extends Equatable {
  final Community community;

  const CreateCommunityParams({required this.community});

  @override
  List<Object?> get props => [community];
}
