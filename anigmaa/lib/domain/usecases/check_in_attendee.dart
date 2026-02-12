import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event_attendee.dart';
import '../repositories/event_repository.dart';

/// Use case for checking in an attendee to an event
/// Only accessible to event hosts
class CheckInAttendee implements UseCase<EventAttendee, CheckInAttendeeParams> {
  final EventRepository repository;

  CheckInAttendee(this.repository);

  @override
  Future<Either<Failure, EventAttendee>> call(CheckInAttendeeParams params) async {
    return await repository.checkInAttendee(
      eventId: params.eventId,
      userId: params.userId,
      ticketId: params.ticketId,
    );
  }
}

class CheckInAttendeeParams extends Equatable {
  final String eventId;
  final String userId;
  final String ticketId;

  const CheckInAttendeeParams({
    required this.eventId,
    required this.userId,
    required this.ticketId,
  });

  @override
  List<Object> get props => [eventId, userId, ticketId];
}
