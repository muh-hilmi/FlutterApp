import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/ranked_feed.dart';

abstract class RankingRepository {
  Future<Either<Failure, RankedFeed>> getRankedFeed(RankingRequest request);
}
