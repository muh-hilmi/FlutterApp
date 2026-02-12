import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class CreateEvent implements UseCase<Event, CreateEventParams> {
  final EventRepository repository;

  CreateEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(CreateEventParams params) async {
    return await repository.createEvent(params.event);
  }
}

class CreateEventParams {
  final Event event;

  CreateEventParams({required this.event});
}