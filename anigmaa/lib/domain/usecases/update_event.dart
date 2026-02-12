import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

/// Use case for updating an existing event
/// Calls PUT /api/v1/events/{event_id} endpoint
/// Preconditions: user must be host, event must have 0 attendees, status must be upcoming
class UpdateEvent implements UseCase<Event, UpdateEventParams> {
  final EventRepository repository;

  UpdateEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(UpdateEventParams params) async {
    return await repository.updateEvent(params.event);
  }
}

/// Parameters for UpdateEvent use case
class UpdateEventParams {
  final Event event;

  const UpdateEventParams({required this.event});
}
