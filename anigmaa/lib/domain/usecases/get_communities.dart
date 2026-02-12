import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../repositories/community_repository.dart';

class GetCommunities implements UseCase<PaginatedResponse<Community>, GetCommunitiesParams> {
  final CommunityRepository repository;

  GetCommunities(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Community>>> call(GetCommunitiesParams params) async {
    return await repository.getCommunities(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetCommunitiesParams {
  final int limit;
  final int offset;

  const GetCommunitiesParams({
    this.limit = 20,
    this.offset = 0,
  });
}
