import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/community_repository.dart';

class LeaveCommunity implements UseCase<void, LeaveCommunityParams> {
  final CommunityRepository repository;

  LeaveCommunity(this.repository);

  @override
  Future<Either<Failure, void>> call(LeaveCommunityParams params) async {
    return await repository.leaveCommunity(params.communityId, params.userId);
  }
}

class LeaveCommunityParams extends Equatable {
  final String communityId;
  final String userId;

  const LeaveCommunityParams({
    required this.communityId,
    required this.userId,
  });

  @override
  List<Object?> get props => [communityId, userId];
}
