import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/services/payment_service.dart';
import '../../core/utils/attendance_code_generator.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_transaction.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/ticket_local_datasource.dart';
import '../datasources/ticket_remote_datasource.dart';
import '../models/ticket_model.dart';
import '../models/ticket_transaction_model.dart';

/// Implementation of TicketRepository
///
/// Handles ticket purchases with Midtrans payment integration
class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;
  final TicketLocalDataSource localDataSource;
  final PaymentService paymentService;
  final EventRepository eventRepository;
  final Uuid uuid = const Uuid();

  TicketRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.paymentService,
    required this.eventRepository,
  });

  @override
  Future<Either<Failure, Ticket>> purchaseTicket({
    required String userId,
    required String eventId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  }) async {
    try {
      // For free events, call backend API directly
      if (amount == 0) {
        try {
          // Call backend API to purchase free ticket
          final apiResponse = await remoteDataSource.purchaseTicketViaAPI(
            eventId: eventId,
            paymentMethod: null, // null for free events
          );

          // Fetch ticket details from API response
          final ticketData = apiResponse['ticket'];
          if (ticketData != null && ticketData is Map<String, dynamic>) {
            final ticket = TicketModel.fromJson(ticketData);

            // Save to local storage as well
            await localDataSource.saveTicket(ticket);

            // Create transaction record
            final transaction = TicketTransactionModel(
              id: apiResponse['transaction_id']?.toString() ?? uuid.v4(),
              ticketId: ticket.id,
              userId: userId,
              eventId: eventId,
              amount: 0.0,
              status: 'completed',
              paymentMethod: 'free',
              paymentGatewayId: apiResponse['transaction_id']?.toString(),
              createdAt: DateTime.now(),
              completedAt: DateTime.now(),
            );

            await localDataSource.saveTransaction(transaction);

            return Right(ticket.toEntity());
          }
        } on Failure catch (f) {
          // Failure from remote datasource
          // logger.e('[TicketRepository] API purchase failed: ${f.message}');
          return Left(f);
        } catch (e) {
          // logger.e('[TicketRepository] Unexpected error: $e');
          // logger.e('[TicketRepository] Stack trace: $stackTrace');
          // Try to extract message from exception
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          return Left(ServerFailure(errorMessage));
        }
      }

      // For paid events, use existing Midtrans flow
      // Generate unique ticket ID and attendance code
      final ticketId = uuid.v4();
      final existingTickets = await localDataSource.getAllTickets();
      final existingCodes = existingTickets
          .map((t) => t.attendanceCode)
          .toSet();
      final attendanceCode = AttendanceCodeGenerator.generateUnique(
        existingCodes,
      );

      // Process payment via Midtrans
      final paymentResult = await paymentService.processPayment(
        eventId: eventId,
        userId: userId,
        ticketId: ticketId,
        amount: amount,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );

      if (!paymentResult.success) {
        return Left(ServerFailure(paymentResult.message));
      }

      // Fetch event details to populate ticket
      final eventResult = await eventRepository.getEventById(eventId);
      String? eventTitle;
      DateTime? eventStartTime;
      String? eventLocation;

      eventResult.fold(
        (failure) {
          // If event fetch fails, use default values
          print('[TicketRepository] Failed to fetch event details: $failure');
        },
        (event) {
          eventTitle = event.title;
          eventStartTime = event.startTime;
          eventLocation = event.location.name;
        },
      );

      // Create ticket with event details (may be null if fetch failed)
      final ticket = TicketModel(
        id: ticketId,
        userId: userId,
        eventId: eventId,
        attendanceCode: attendanceCode,
        pricePaid: amount,
        purchasedAt: DateTime.now(),
        eventTitle: eventTitle,
        eventStartTime: eventStartTime,
        eventLocation: eventLocation,
      );

      // Save ticket
      await localDataSource.saveTicket(ticket);

      // Create transaction record
      final transaction = TicketTransactionModel(
        id: paymentResult.transactionId ?? uuid.v4(),
        ticketId: ticketId,
        userId: userId,
        eventId: eventId,
        amount: amount,
        status: _transactionStatusToString(paymentResult.status),
        paymentMethod: paymentResult.paymentType ?? 'free',
        paymentGatewayId: paymentResult.transactionId,
        paymentGatewayResponse: paymentResult.response?.toString(),
        createdAt: DateTime.now(),
        completedAt: paymentResult.success ? DateTime.now() : null,
      );

      await localDataSource.saveTransaction(transaction);

      return Right(ticket.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ticket>>> getUserTickets(String userId) async {
    try {
      final tickets = await localDataSource.getUserTickets(userId);
      return Right(tickets.map((t) => t.toEntity()).toList());
    } catch (e) {
      // Return empty list instead of error if cache is empty
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<Ticket>>> getEventTickets(String eventId) async {
    try {
      final tickets = await localDataSource.getEventTickets(eventId);
      return Right(tickets.map((t) => t.toEntity()).toList());
    } catch (e) {
      // Return empty list instead of error if cache is empty
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, Ticket>> getTicketById(String ticketId) async {
    try {
      final ticket = await localDataSource.getTicketById(ticketId);
      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }
      return Right(ticket.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> getTicketByCode(String attendanceCode) async {
    try {
      final normalizedCode = AttendanceCodeGenerator.normalize(attendanceCode);
      final ticket = await localDataSource.getTicketByCode(normalizedCode);

      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }

      return Right(ticket.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> checkInTicket(String ticketId) async {
    try {
      final ticket = await localDataSource.getTicketById(ticketId);

      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }

      if (ticket.isCheckedIn) {
        return Left(ServerFailure('Ticket already checked in'));
      }

      // Update ticket
      final updatedTicket = TicketModel(
        id: ticket.id,
        userId: ticket.userId,
        eventId: ticket.eventId,
        attendanceCode: ticket.attendanceCode,
        pricePaid: ticket.pricePaid,
        purchasedAt: ticket.purchasedAt,
        isCheckedIn: true,
        checkedInAt: DateTime.now(),
        status: ticket.status,
      );

      await localDataSource.updateTicket(updatedTicket);
      return Right(updatedTicket.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ticket>> cancelTicket(String ticketId) async {
    try {
      final ticket = await localDataSource.getTicketById(ticketId);

      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }

      if (ticket.isCheckedIn) {
        return Left(ServerFailure('Cannot cancel checked-in ticket'));
      }

      // Update ticket status
      final updatedTicket = TicketModel(
        id: ticket.id,
        userId: ticket.userId,
        eventId: ticket.eventId,
        attendanceCode: ticket.attendanceCode,
        pricePaid: ticket.pricePaid,
        purchasedAt: ticket.purchasedAt,
        isCheckedIn: ticket.isCheckedIn,
        checkedInAt: ticket.checkedInAt,
        status: 'cancelled',
      );

      await localDataSource.updateTicket(updatedTicket);
      return Right(updatedTicket.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TicketTransaction>>> getUserTransactions(
    String userId,
  ) async {
    try {
      final transactions = await localDataSource.getUserTransactions(userId);
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      // Return empty list instead of error if cache is empty
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, TicketTransaction>> getTransactionById(
    String transactionId,
  ) async {
    try {
      final transaction = await localDataSource.getTransactionById(
        transactionId,
      );
      if (transaction == null) {
        return Left(ServerFailure('Transaction not found'));
      }
      return Right(transaction.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  /// Helper: Convert TransactionStatus to string
  String _transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.cancelled:
        return 'cancelled';
      case TransactionStatus.refunded:
        return 'refunded';
    }
  }
}
