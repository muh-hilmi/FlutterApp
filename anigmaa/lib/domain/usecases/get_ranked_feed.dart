import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/ranked_feed.dart';
import '../repositories/ranking_repository.dart';

class GetRankedFeed implements UseCase<RankedFeed, RankingRequest> {
  final RankingRepository repository;

  GetRankedFeed(this.repository);

  @override
  Future<Either<Failure, RankedFeed>> call(RankingRequest params) async {
    return await repository.getRankedFeed(params);
  }
}
