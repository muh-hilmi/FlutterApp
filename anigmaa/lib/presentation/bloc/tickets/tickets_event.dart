import 'package:equatable/equatable.dart';

abstract class TicketsEvent extends Equatable {
  const TicketsEvent();

  @override
  List<Object?> get props => [];
}

/// Load user's tickets
class LoadUserTickets extends TicketsEvent {
  final String userId;

  const LoadUserTickets(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Purchase a ticket
class PurchaseTicketRequested extends TicketsEvent {
  final String userId;
  final String eventId;
  final double amount;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;

  const PurchaseTicketRequested({
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

/// Check in a ticket
class CheckInTicketRequested extends TicketsEvent {
  final String? ticketId;
  final String? attendanceCode;
  final String? eventId; // required for host check-in flow

  const CheckInTicketRequested({
    this.ticketId,
    this.attendanceCode,
    this.eventId,
  });

  const CheckInTicketRequested.byId(String id)
      : ticketId = id,
        attendanceCode = null,
        eventId = null;

  const CheckInTicketRequested.byCode(String code)
      : ticketId = null,
        attendanceCode = code,
        eventId = null;

  @override
  List<Object?> get props => [ticketId, attendanceCode, eventId];
}

/// Load all tickets for a specific event (host stats)
class LoadEventTickets extends TicketsEvent {
  final String eventId;

  const LoadEventTickets(this.eventId);

  @override
  List<Object> get props => [eventId];
}

/// Load ticket by ID
class LoadTicketById extends TicketsEvent {
  final String ticketId;

  const LoadTicketById(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}

/// Load ticket by attendance code
class LoadTicketByCode extends TicketsEvent {
  final String attendanceCode;

  const LoadTicketByCode(this.attendanceCode);

  @override
  List<Object> get props => [attendanceCode];
}

/// Find a user's ticket for a specific event
class LoadTicketForEvent extends TicketsEvent {
  final String userId;
  final String eventId;

  const LoadTicketForEvent({required this.userId, required this.eventId});

  @override
  List<Object> get props => [userId, eventId];
}
