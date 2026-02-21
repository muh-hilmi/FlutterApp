import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

class CancelTicket {
  final TicketRepository repository;

  CancelTicket(this.repository);

  Future<Either<Failure, Ticket>> call(String ticketId) {
    return repository.cancelTicket(ticketId);
  }
}
