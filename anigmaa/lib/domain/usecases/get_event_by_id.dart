import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventById {
  final EventRepository repository;

  GetEventById(this.repository);

  Future<Either<Failure, Event>> call(String eventId) async {
    return await repository.getEventById(eventId);
  }
}
