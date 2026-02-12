import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/check_in_ticket.dart';
import '../../../domain/usecases/get_user_tickets.dart';
import '../../../domain/usecases/purchase_ticket.dart';
import 'tickets_event.dart';
import 'tickets_state.dart';

class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  final PurchaseTicket purchaseTicket;
  final GetUserTickets getUserTickets;
  final CheckInTicket checkInTicket;

  TicketsBloc({
    required this.purchaseTicket,
    required this.getUserTickets,
    required this.checkInTicket,
  }) : super(TicketsInitial()) {
    on<LoadUserTickets>(_onLoadUserTickets);
    on<PurchaseTicketRequested>(_onPurchaseTicketRequested);
    on<CheckInTicketRequested>(_onCheckInTicketRequested);
  }

  Future<void> _onLoadUserTickets(
    LoadUserTickets event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    final result = await getUserTickets(GetUserTicketsParams(userId: event.userId));

    result.fold(
      (failure) => emit(TicketsError(failure.message)),
      (tickets) => emit(TicketsLoaded(tickets)),
    );
  }

  Future<void> _onPurchaseTicketRequested(
    PurchaseTicketRequested event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    print('[TicketsBloc] Purchasing ticket for event ${event.eventId}');

    final result = await purchaseTicket(
      PurchaseTicketParams(
        userId: event.userId,
        eventId: event.eventId,
        amount: event.amount,
        customerName: event.customerName,
        customerEmail: event.customerEmail,
        customerPhone: event.customerPhone,
      ),
    );

    result.fold(
      (failure) {
        print('[TicketsBloc] Purchase failed: ${failure.message}');
        emit(TicketsError(failure.message));
      },
      (ticket) {
        print('[TicketsBloc] Purchase success: ${ticket.id}');
        emit(TicketPurchased(ticket));
      },
    );
  }

  Future<void> _onCheckInTicketRequested(
    CheckInTicketRequested event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    final CheckInTicketParams params;
    if (event.ticketId != null) {
      params = CheckInTicketParams.byId(event.ticketId!);
    } else if (event.attendanceCode != null) {
      params = CheckInTicketParams.byCode(event.attendanceCode!);
    } else {
      emit(const TicketsError('Invalid check-in parameters'));
      return;
    }

    final result = await checkInTicket(params);

    result.fold(
      (failure) => emit(TicketsError(failure.message)),
      (ticket) => emit(TicketCheckedIn(ticket)),
    );
  }
}
