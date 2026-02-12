import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event_attendee.dart';
import '../repositories/event_repository.dart';

/// Use case for getting event attendees list
/// Only accessible to event hosts
class GetEventAttendees implements UseCase<List<EventAttendee>, GetEventAttendeesParams> {
  final EventRepository repository;

  GetEventAttendees(this.repository);

  @override
  Future<Either<Failure, List<EventAttendee>>> call(GetEventAttendeesParams params) async {
    return await repository.getEventAttendees(
      eventId: params.eventId,
      status: params.status,
      search: params.search,
    );
  }
}

class GetEventAttendeesParams extends Equatable {
  final String eventId;
  final String? status; // 'confirmed', 'pending', or null for all
  final String? search; // Search by name

  const GetEventAttendeesParams({
    required this.eventId,
    this.status,
    this.search,
  });

  @override
  List<Object?> get props => [eventId, status, search];
}
