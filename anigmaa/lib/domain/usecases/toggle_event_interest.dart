import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class ToggleEventInterest {
  final EventRepository repository;

  ToggleEventInterest(this.repository);

  Future<Either<Failure, Event>> call(String eventId, String userId) async {
    return await repository.toggleEventInterest(eventId, userId);
  }
}
