part of 'payment_bloc.dart';

enum PaymentStatus { initial, loading, initiated, processing, success, error, cancelled }

class PaymentState extends Equatable {
  final PaymentStatus status;
  final PaymentMethod? paymentMethod;
  final Event? event;
  final String? transactionId;
  final String? paymentUrl;
  final String? errorMessage;

  const PaymentState({
    required this.status,
    this.paymentMethod,
    this.event,
    this.transactionId,
    this.paymentUrl,
    this.errorMessage,
  });

  const PaymentState.initial()
      : status = PaymentStatus.initial,
        paymentMethod = null,
        event = null,
        transactionId = null,
        paymentUrl = null,
        errorMessage = null;

  PaymentState copyWith({
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    Event? event,
    String? transactionId,
    String? paymentUrl,
    String? errorMessage,
    bool clearTransactionId = false,
    bool clearPaymentUrl = false,
  }) {
    return PaymentState(
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      event: event ?? this.event,
      transactionId: clearTransactionId ? null : (transactionId ?? this.transactionId),
      paymentUrl: clearPaymentUrl ? null : (paymentUrl ?? this.paymentUrl),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        paymentMethod,
        event,
        transactionId,
        paymentUrl,
        errorMessage,
      ];

  bool get isLoading => status == PaymentStatus.loading || status == PaymentStatus.processing;
  bool get isSuccess => status == PaymentStatus.success;
  bool get isError => status == PaymentStatus.error;
  bool get isInitiated => status == PaymentStatus.initiated;
}