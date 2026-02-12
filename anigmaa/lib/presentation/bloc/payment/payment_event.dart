part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class InitiatePayment extends PaymentEvent {
  final Event event;
  final PaymentMethod paymentMethod;
  final int totalAmount;

  const InitiatePayment({
    required this.event,
    required this.paymentMethod,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [event, paymentMethod, totalAmount];
}

class ProcessPayment extends PaymentEvent {
  final String transactionId;
  final String paymentToken;

  const ProcessPayment({
    required this.transactionId,
    required this.paymentToken,
  });

  @override
  List<Object?> get props => [transactionId, paymentToken];
}

class PaymentSuccess extends PaymentEvent {
  final String transactionId;
  final String? receiptUrl;

  const PaymentSuccess({required this.transactionId, this.receiptUrl});

  @override
  List<Object?> get props => [transactionId, receiptUrl];
}

class PaymentFailed extends PaymentEvent {
  final String errorMessage;

  const PaymentFailed(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class ResetPaymentState extends PaymentEvent {
  const ResetPaymentState();

  @override
  List<Object?> get props => [];
}
