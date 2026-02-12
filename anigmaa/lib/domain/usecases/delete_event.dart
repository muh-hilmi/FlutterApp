import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/event_repository.dart';

/// Use case for deleting an event created by the current user
/// Calls DELETE /api/v1/events/{event_id} endpoint
/// Preconditions: user must be host, event must have 0 attendees, status must be upcoming
class DeleteEvent implements UseCase<void, DeleteEventParams> {
  final EventRepository repository;

  DeleteEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteEventParams params) async {
    return await repository.deleteEvent(params.eventId);
  }
}

/// Parameters for DeleteEvent use case
class DeleteEventParams {
  final String eventId;

  const DeleteEventParams({required this.eventId});
}
