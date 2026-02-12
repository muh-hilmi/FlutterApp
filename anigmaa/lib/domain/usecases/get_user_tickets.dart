import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Use case for retrieving all tickets for a user
class GetUserTickets implements UseCase<List<Ticket>, GetUserTicketsParams> {
  final TicketRepository repository;

  GetUserTickets(this.repository);

  @override
  Future<Either<Failure, List<Ticket>>> call(
    GetUserTicketsParams params,
  ) async {
    return await repository.getUserTickets(params.userId);
  }
}

class GetUserTicketsParams extends Equatable {
  final String userId;

  const GetUserTicketsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
