import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../../data/models/midtrans_payment_model.dart';
import '../../../../data/services/midtrans_payment_service.dart';

// BLoC Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class InitiatePaymentEvent extends PaymentEvent {
  final PaymentInitRequest request;

  const InitiatePaymentEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class CheckPaymentStatusEvent extends PaymentEvent {
  final String orderId;

  const CheckPaymentStatusEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class ResetPaymentEvent extends PaymentEvent {}

// BLoC States
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentTokenLoaded extends PaymentState {
  final String snapToken;
  final String redirectUrl;
  final String orderId;

  const PaymentTokenLoaded({
    required this.snapToken,
    required this.redirectUrl,
    required this.orderId,
  });

  @override
  List<Object?> get props => [snapToken, redirectUrl, orderId];
}

class PaymentSuccess extends PaymentState {
  final String orderId;
  final String? transactionId;
  final String paymentType;
  final TransactionStatus status;

  const PaymentSuccess({
    required this.orderId,
    this.transactionId,
    required this.paymentType,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, transactionId, paymentType, status];
}

class PaymentFailed extends PaymentState {
  final String orderId;
  final String message;

  const PaymentFailed({
    required this.orderId,
    required this.message,
  });

  @override
  List<Object?> get props => [orderId, message];
}

class PaymentPending extends PaymentState {
  final String orderId;

  const PaymentPending(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC Implementation
class MidtransPaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final MidtransPaymentService _paymentService;
  final Logger _logger = Logger();

  MidtransPaymentBloc(this._paymentService) : super(PaymentInitial()) {
    on<InitiatePaymentEvent>(_onInitiatePayment);
    on<CheckPaymentStatusEvent>(_onCheckPaymentStatus);
    on<ResetPaymentEvent>(_onResetPayment);
  }

  Future<void> _onInitiatePayment(
    InitiatePaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final response = await _paymentService.initiatePayment(event.request);

      emit(PaymentTokenLoaded(
        snapToken: response.token,
        redirectUrl: response.redirectUrl,
        orderId: event.request.orderId,
      ));
    } catch (e) {
      _logger.e('Error initiating payment: $e');
      emit(PaymentError('Failed to initiate payment: ${e.toString()}'));
    }
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatusEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final status = await _paymentService.checkPaymentStatus(event.orderId);

      if (status.transactionStatus.isSuccess) {
        emit(PaymentSuccess(
          orderId: status.orderId,
          transactionId: status.transactionId,
          paymentType: status.paymentType,
          status: status.transactionStatus,
        ));
      } else if (status.transactionStatus.isPending) {
        emit(PaymentPending(status.orderId));
      } else {
        emit(PaymentFailed(
          orderId: status.orderId,
          message: 'Payment ${status.transactionStatus.value}',
        ));
      }
    } catch (e) {
      _logger.e('Error checking payment status: $e');
      emit(PaymentError('Failed to check payment status: ${e.toString()}'));
    }
  }

  void _onResetPayment(
    ResetPaymentEvent event,
    Emitter<PaymentState> emit,
  ) {
    emit(PaymentInitial());
  }

  // Manual payment result handler (call this after WebView payment completion)
  // Note: Use add() for success, direct emit for failure is done via internal event
  void handlePaymentResult({
    required String orderId,
    required bool success,
    String? errorMessage,
  }) {
    if (success) {
      add(CheckPaymentStatusEvent(orderId));
    } else {
      // Add a reset event first, then the error will be handled by caller
      add(ResetPaymentEvent());
      // Caller should navigate away or show error
    }
  }
}
