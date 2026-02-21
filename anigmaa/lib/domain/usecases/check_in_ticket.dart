import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Use case for checking in a ticket at an event
///
/// Can check in by ticket ID or attendance code
class CheckInTicket implements UseCase<Ticket, CheckInTicketParams> {
  final TicketRepository repository;

  CheckInTicket(this.repository);

  @override
  Future<Either<Failure, Ticket>> call(CheckInTicketParams params) async {
    // Host flow: event_id + attendance_code → call backend directly
    if (params.eventId != null && params.attendanceCode != null) {
      return await repository.checkInByCode(
        params.eventId!,
        params.attendanceCode!,
      );
    }

    // If attendance code provided (no eventId), find ticket locally first
    if (params.attendanceCode != null) {
      final ticketResult = await repository.getTicketByCode(
        params.attendanceCode!,
      );

      return ticketResult.fold(
        (failure) => Left(failure),
        (ticket) => repository.checkInTicket(ticket.id),
      );
    }

    // Otherwise, check in by ticket ID
    return await repository.checkInTicket(params.ticketId!);
  }
}

class CheckInTicketParams extends Equatable {
  final String? ticketId;
  final String? attendanceCode;
  final String? eventId;

  const CheckInTicketParams({
    this.ticketId,
    this.attendanceCode,
    this.eventId,
  }) : assert(
          ticketId != null || attendanceCode != null,
          'Either ticketId or attendanceCode must be provided',
        );

  const CheckInTicketParams.byId(String id)
      : ticketId = id,
        attendanceCode = null,
        eventId = null;

  const CheckInTicketParams.byCode(String code)
      : ticketId = null,
        attendanceCode = code,
        eventId = null;

  @override
  List<Object?> get props => [ticketId, attendanceCode, eventId];
}
