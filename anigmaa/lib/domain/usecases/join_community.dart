import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/community_repository.dart';

class JoinCommunity implements UseCase<void, JoinCommunityParams> {
  final CommunityRepository repository;

  JoinCommunity(this.repository);

  @override
  Future<Either<Failure, void>> call(JoinCommunityParams params) async {
    return await repository.joinCommunity(params.communityId, params.userId);
  }
}

class JoinCommunityParams extends Equatable {
  final String communityId;
  final String userId;

  const JoinCommunityParams({
    required this.communityId,
    required this.userId,
  });

  @override
  List<Object?> get props => [communityId, userId];
}
