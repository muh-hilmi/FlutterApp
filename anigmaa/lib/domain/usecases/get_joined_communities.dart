import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../repositories/community_repository.dart';

class GetJoinedCommunities implements UseCase<List<Community>, GetJoinedCommunitiesParams> {
  final CommunityRepository repository;

  GetJoinedCommunities(this.repository);

  @override
  Future<Either<Failure, List<Community>>> call(GetJoinedCommunitiesParams params) async {
    final result = await repository.getJoinedCommunities(params.userId);
    return result.fold(
      (failure) => Left(failure),
      (response) => Right(response.data),
    );
  }
}

class GetJoinedCommunitiesParams extends Equatable {
  final String userId;

  const GetJoinedCommunitiesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
