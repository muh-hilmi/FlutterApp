import 'package:equatable/equatable.dart';

/// Transaction record for ticket purchases
///
/// Tracks payment information, status, and integration with payment gateway
/// Used for payment reconciliation and refund processing
class TicketTransaction extends Equatable {
  final String id;
  final String ticketId;
  final String userId;
  final String eventId;
  final double amount;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentGatewayId; // Midtrans transaction ID
  final String? paymentGatewayResponse; // Full response JSON
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? failureReason;

  const TicketTransaction({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.eventId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.paymentGatewayId,
    this.paymentGatewayResponse,
    required this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.failureReason,
  });

  bool get isSuccessful => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;
  bool get isFailed => status == TransactionStatus.failed;

  @override
  List<Object?> get props => [
        id,
        ticketId,
        userId,
        eventId,
        amount,
        status,
        paymentMethod,
        paymentGatewayId,
        paymentGatewayResponse,
        createdAt,
        completedAt,
        cancelledAt,
        failureReason,
      ];

  TicketTransaction copyWith({
    String? id,
    String? ticketId,
    String? userId,
    String? eventId,
    double? amount,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentGatewayId,
    String? paymentGatewayResponse,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? failureReason,
  }) {
    return TicketTransaction(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentGatewayId: paymentGatewayId ?? this.paymentGatewayId,
      paymentGatewayResponse:
          paymentGatewayResponse ?? this.paymentGatewayResponse,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  String toString() {
    return 'TicketTransaction(id: $id, amount: $amount, status: $status, '
        'method: $paymentMethod, gatewayId: $paymentGatewayId)';
  }
}

/// Transaction status
enum TransactionStatus {
  pending,    // Payment initiated, waiting for completion
  completed,  // Payment successful
  failed,     // Payment failed
  cancelled,  // User cancelled
  refunded,   // Payment refunded
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isTerminal =>
      this == TransactionStatus.completed ||
      this == TransactionStatus.failed ||
      this == TransactionStatus.cancelled;
}

/// Payment methods supported by the app
/// All paid methods use Midtrans gateway
enum PaymentMethod {
  // Midtrans-processed methods (instant payment)
  qris,
  gopay,
  shopeePay,
  dana,
  bcaVa,
  mandiriVa,
  bniVa,
  permataVa,
  otherVa,

  // Manual methods (require upload proof)
  bankTransfer,

  creditCard,

  free, // For free event reservations
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.gopay:
        return 'GoPay';
      case PaymentMethod.shopeePay:
        return 'ShopeePay';
      case PaymentMethod.dana:
        return 'DANA';
      case PaymentMethod.bcaVa:
        return 'BCA Virtual Account';
      case PaymentMethod.mandiriVa:
        return 'Mandiri Bill';
      case PaymentMethod.bniVa:
        return 'BNI Virtual Account';
      case PaymentMethod.permataVa:
        return 'Permata VA';
      case PaymentMethod.otherVa:
        return 'Bank Lainnya';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank Manual';
      case PaymentMethod.creditCard:
        return 'Kartu Kredit/Debit';
      case PaymentMethod.free:
        return 'Gratis';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.qris:
        return '📲';
      case PaymentMethod.gopay:
        return '🟢';
      case PaymentMethod.shopeePay:
        return '🟠';
      case PaymentMethod.dana:
        return '🔵';
      case PaymentMethod.bcaVa:
        return '🔵';
      case PaymentMethod.mandiriVa:
        return '💙';
      case PaymentMethod.bniVa:
        return '🅱️';
      case PaymentMethod.permataVa:
        return '🟣';
      case PaymentMethod.otherVa:
        return '🏦';
      case PaymentMethod.bankTransfer:
        return '🏦';
      case PaymentMethod.creditCard:
        return '💳';
      case PaymentMethod.free:
        return '🎁';
    }
  }

  bool get isEWallet =>
      this == PaymentMethod.qris ||
      this == PaymentMethod.gopay ||
      this == PaymentMethod.shopeePay ||
      this == PaymentMethod.dana;

  bool get isVA =>
      this == PaymentMethod.bcaVa ||
      this == PaymentMethod.mandiriVa ||
      this == PaymentMethod.bniVa ||
      this == PaymentMethod.permataVa ||
      this == PaymentMethod.otherVa;

  bool get isPaid =>
      this != PaymentMethod.free;
}
