import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

/// Use case for retrieving events created by the current user
/// Calls GET /api/v1/users/me/events endpoint
class GetMyEvents implements UseCase<List<Event>, GetMyEventsParams> {
  final EventRepository repository;

  GetMyEvents(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(GetMyEventsParams params) async {
    // Delegate to repository's getMyEvents method
    return await repository.getMyEvents(status: params.status);
  }
}

/// Parameters for GetMyEvents use case
class GetMyEventsParams {
  /// Optional status filter: 'upcoming', 'ongoing', 'ended', 'cancelled'
  final String? status;

  const GetMyEventsParams({this.status});
}
