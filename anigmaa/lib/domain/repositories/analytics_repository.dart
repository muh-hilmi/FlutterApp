import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/analytics.dart';

abstract class AnalyticsRepository {
  /// Get comprehensive analytics for a specific event (host only)
  Future<Either<Failure, EventAnalytics>> getEventAnalytics(String eventId);

  /// Get detailed transaction list for an event (host only)
  Future<Either<Failure, List<TransactionDetail>>> getEventTransactions(
    String eventId, {
    String? status,
    int limit = 50,
    int offset = 0,
  });

  /// Get revenue summary for all events created by the host
  Future<Either<Failure, HostRevenueSummary>> getHostRevenueSummary({
    String period = 'all',
  });

  /// Get list of events with revenue information
  Future<Either<Failure, List<EventRevenueSummary>>> getHostEvents({
    String? status,
    int limit = 20,
    int offset = 0,
  });
}
