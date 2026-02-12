import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Use case for purchasing an event ticket
///
/// Handles payment processing and ticket generation
class PurchaseTicket implements UseCase<Ticket, PurchaseTicketParams> {
  final TicketRepository repository;

  PurchaseTicket(this.repository);

  @override
  Future<Either<Failure, Ticket>> call(PurchaseTicketParams params) async {
    return await repository.purchaseTicket(
      userId: params.userId,
      eventId: params.eventId,
      amount: params.amount,
      customerName: params.customerName,
      customerEmail: params.customerEmail,
      customerPhone: params.customerPhone,
    );
  }
}

class PurchaseTicketParams extends Equatable {
  final String userId;
  final String eventId;
  final double amount;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;

  const PurchaseTicketParams({
    required this.userId,
    required this.eventId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
  });

  @override
  List<Object?> get props => [
        userId,
        eventId,
        amount,
        customerName,
        customerEmail,
        customerPhone,
      ];
}
