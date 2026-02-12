import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;

  AnalyticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, EventAnalytics>> getEventAnalytics(String eventId) async {
    try {
      final analytics = await remoteDataSource.getEventAnalytics(eventId);
      return Right(analytics);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get event analytics: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransactionDetail>>> getEventTransactions(
    String eventId, {
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final transactions = await remoteDataSource.getEventTransactions(
        eventId,
        status: status,
        limit: limit,
        offset: offset,
      );
      return Right(transactions);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get event transactions: $e'));
    }
  }

  @override
  Future<Either<Failure, HostRevenueSummary>> getHostRevenueSummary({
    String period = 'all',
  }) async {
    try {
      final summary = await remoteDataSource.getHostRevenueSummary(period: period);
      return Right(summary);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get host revenue summary: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EventRevenueSummary>>> getHostEvents({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final events = await remoteDataSource.getHostEvents(
        status: status,
        limit: limit,
        offset: offset,
      );
      return Right(events);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get host events: $e'));
    }
  }
}
