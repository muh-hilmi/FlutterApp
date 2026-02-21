import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Use case for fetching all tickets for a specific event
///
/// Used by hosts to see attendees and check-in stats
class GetEventTickets {
  final TicketRepository repository;

  GetEventTickets(this.repository);

  Future<Either<Failure, List<Ticket>>> call(String eventId) async {
    return await repository.getEventTickets(eventId);
  }
}
