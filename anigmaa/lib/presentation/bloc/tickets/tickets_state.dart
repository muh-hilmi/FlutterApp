import 'package:equatable/equatable.dart';
import '../../../domain/entities/ticket.dart';

abstract class TicketsState extends Equatable {
  const TicketsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TicketsInitial extends TicketsState {}

/// Loading state
class TicketsLoading extends TicketsState {}

/// Tickets loaded successfully
class TicketsLoaded extends TicketsState {
  final List<Ticket> tickets;

  const TicketsLoaded(this.tickets);

  @override
  List<Object> get props => [tickets];
}

/// Single ticket loaded
class TicketLoaded extends TicketsState {
  final Ticket ticket;

  const TicketLoaded(this.ticket);

  @override
  List<Object> get props => [ticket];
}

/// Ticket purchased successfully
class TicketPurchased extends TicketsState {
  final Ticket ticket;

  const TicketPurchased(this.ticket);

  @override
  List<Object> get props => [ticket];
}

/// Ticket checked in successfully
class TicketCheckedIn extends TicketsState {
  final Ticket ticket;

  const TicketCheckedIn(this.ticket);

  @override
  List<Object> get props => [ticket];
}

/// Ticket cancelled successfully
class TicketCancelled extends TicketsState {
  final Ticket ticket;

  const TicketCancelled(this.ticket);

  @override
  List<Object> get props => [ticket];
}

/// Event tickets loaded (for host stats)
class EventTicketsLoaded extends TicketsState {
  final List<Ticket> tickets;
  final int checkedInCount;
  final int totalCount;

  EventTicketsLoaded(this.tickets)
      : checkedInCount = tickets.where((t) => t.isCheckedIn).length,
        totalCount = tickets.length;

  @override
  List<Object> get props => [tickets, checkedInCount, totalCount];
}

/// Error state
class TicketsError extends TicketsState {
  final String message;

  const TicketsError(this.message);

  @override
  List<Object> get props => [message];
}
