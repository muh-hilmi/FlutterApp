import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/check_in_ticket.dart';
import '../../../domain/usecases/get_user_tickets.dart';
import '../../../domain/usecases/get_event_tickets.dart';
import '../../../domain/usecases/purchase_ticket.dart';
import '../../../domain/usecases/cancel_ticket.dart';
import '../../../core/utils/app_logger.dart';
import 'tickets_event.dart';
import 'tickets_state.dart';

class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  final PurchaseTicket purchaseTicket;
  final GetUserTickets getUserTickets;
  final CheckInTicket checkInTicket;
  final GetEventTickets getEventTickets;
  final CancelTicket cancelTicket;

  TicketsBloc({
    required this.purchaseTicket,
    required this.getUserTickets,
    required this.checkInTicket,
    required this.getEventTickets,
    required this.cancelTicket,
  }) : super(TicketsInitial()) {
    on<LoadUserTickets>(_onLoadUserTickets);
    on<PurchaseTicketRequested>(_onPurchaseTicketRequested);
    on<CheckInTicketRequested>(_onCheckInTicketRequested);
    on<LoadTicketForEvent>(_onLoadTicketForEvent);
    on<LoadEventTickets>(_onLoadEventTickets);
    on<CancelTicketRequested>(_onCancelTicketRequested);
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

    AppLogger().info('[TicketsBloc] Purchasing ticket for event ${event.eventId}');

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
        AppLogger().error('[TicketsBloc] Purchase failed: ${failure.message}');
        emit(TicketsError(failure.message));
      },
      (ticket) {
        AppLogger().info('[TicketsBloc] Purchase success: ${ticket.id}');
        emit(TicketPurchased(ticket));
      },
    );
  }

  Future<void> _onLoadTicketForEvent(
    LoadTicketForEvent event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    final result = await getUserTickets(GetUserTicketsParams(userId: event.userId));

    result.fold(
      (failure) => emit(TicketsError(failure.message)),
      (tickets) {
        final ticket = tickets.where((t) => t.eventId == event.eventId).firstOrNull;
        if (ticket != null) {
          emit(TicketLoaded(ticket));
        } else {
          emit(const TicketsError('Tiket untuk event ini tidak ditemukan'));
        }
      },
    );
  }

  Future<void> _onCheckInTicketRequested(
    CheckInTicketRequested event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    final CheckInTicketParams params;
    if (event.attendanceCode != null && event.eventId != null) {
      // Host flow: direct backend call
      params = CheckInTicketParams(
        attendanceCode: event.attendanceCode,
        eventId: event.eventId,
      );
    } else if (event.ticketId != null) {
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

  Future<void> _onLoadEventTickets(
    LoadEventTickets event,
    Emitter<TicketsState> emit,
  ) async {
    emit(TicketsLoading());

    final result = await getEventTickets(event.eventId);

    result.fold(
      (failure) => emit(TicketsError(failure.message)),
      (tickets) => emit(EventTicketsLoaded(tickets)),
    );
  }

  Future<void> _onCancelTicketRequested(
    CancelTicketRequested event,
    Emitter<TicketsState> emit,
  ) async {
    AppLogger().info('[TicketsBloc] Cancelling ticket: ${event.ticketId}');

    final result = await cancelTicket(event.ticketId);

    result.fold(
      (failure) {
        AppLogger().error('[TicketsBloc] Cancel failed: ${failure.message ?? 'Unknown error'}');
        emit(TicketsError(failure.message ?? 'Gagal membatalkan tiket'));
      },
      (ticket) {
        AppLogger().info('[TicketsBloc] Ticket cancelled: ${ticket.id}');
        emit(TicketCancelled(ticket));
      },
    );
  }
}
