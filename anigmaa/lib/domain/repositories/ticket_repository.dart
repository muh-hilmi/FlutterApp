import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../entities/ticket_transaction.dart';

/// Ticket repository interface
///
/// Handles ticket purchases, retrieval, and check-in operations
abstract class TicketRepository {
  /// Purchase a ticket for an event
  ///
  /// Returns created Ticket on success, Failure on error
  Future<Either<Failure, Ticket>> purchaseTicket({
    required String userId,
    required String eventId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  });

  /// Get all tickets for a user
  Future<Either<Failure, List<Ticket>>> getUserTickets(String userId);

  /// Get tickets for a specific event
  Future<Either<Failure, List<Ticket>>> getEventTickets(String eventId);

  /// Get a single ticket by ID
  Future<Either<Failure, Ticket>> getTicketById(String ticketId);

  /// Get ticket by attendance code
  Future<Either<Failure, Ticket>> getTicketByCode(String attendanceCode);

  /// Check in a ticket
  Future<Either<Failure, Ticket>> checkInTicket(String ticketId);

  /// Cancel a ticket
  Future<Either<Failure, Ticket>> cancelTicket(String ticketId);

  /// Get transaction history for a user
  Future<Either<Failure, List<TicketTransaction>>> getUserTransactions(
    String userId,
  );

  /// Get transaction by ID
  Future<Either<Failure, TicketTransaction>> getTransactionById(
    String transactionId,
  );
}
