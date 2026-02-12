import 'package:equatable/equatable.dart';

/// Transaction entity representing a payment transaction for event tickets
class Transaction extends Equatable {
  final String id;
  final String userId;
  final String ticketId;
  final String eventId;
  final String eventName;
  final double amount;
  final double adminFee;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentProof;
  final String? virtualAccountNumber;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.userId,
    required this.ticketId,
    required this.eventId,
    required this.eventName,
    required this.amount,
    this.adminFee = 0,
    required this.status,
    required this.paymentMethod,
    this.paymentProof,
    this.virtualAccountNumber,
    required this.createdAt,
    this.paidAt,
    this.expiredAt,
    this.metadata,
  });

  /// Get total amount including admin fee
  double get totalAmount => amount + adminFee;

  /// Check if transaction is still pending and not expired
  bool get isPending => status == TransactionStatus.pending &&
                        (expiredAt == null || DateTime.now().isBefore(expiredAt!));

  /// Check if transaction is successful
  bool get isSuccess => status == TransactionStatus.success;

  /// Check if transaction has failed
  bool get isFailed => status == TransactionStatus.failed ||
                       status == TransactionStatus.expired;

  /// Get transaction ID in display format
  String get displayId => 'TRX-${id.substring(0, 8).toUpperCase()}';

  @override
  List<Object?> get props => [
        id,
        userId,
        ticketId,
        eventId,
        eventName,
        amount,
        adminFee,
        status,
        paymentMethod,
        paymentProof,
        virtualAccountNumber,
        createdAt,
        paidAt,
        expiredAt,
        metadata,
      ];

  Transaction copyWith({
    String? id,
    String? userId,
    String? ticketId,
    String? eventId,
    String? eventName,
    double? amount,
    double? adminFee,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentProof,
    String? virtualAccountNumber,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? expiredAt,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ticketId: ticketId ?? this.ticketId,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      amount: amount ?? this.amount,
      adminFee: adminFee ?? this.adminFee,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProof: paymentProof ?? this.paymentProof,
      virtualAccountNumber: virtualAccountNumber ?? this.virtualAccountNumber,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      expiredAt: expiredAt ?? this.expiredAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, eventName: $eventName, amount: $amount, '
        'status: $status, method: $paymentMethod)';
  }
}

/// Transaction status enumeration
enum TransactionStatus {
  pending,    // Menunggu pembayaran
  processing, // Sedang diproses payment gateway
  success,    // Berhasil
  failed,     // Gagal
  cancelled,  // Dibatalkan user
  expired,    // Kadaluarsa (timeout)
  refunded,   // Sudah direfund
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Lagi Diproses';
      case TransactionStatus.success:
        return 'Sukses';
      case TransactionStatus.failed:
        return 'Gagal';
      case TransactionStatus.cancelled:
        return 'Dibatalin';
      case TransactionStatus.expired:
        return 'Udah Expired';
      case TransactionStatus.refunded:
        return 'Direfund';
    }
  }

  bool get isCompleted => this == TransactionStatus.success;
  bool get canRetry => this == TransactionStatus.failed || this == TransactionStatus.expired;
  bool get canCancel => this == TransactionStatus.pending;
}

/// Payment method enumeration
/// Note: All paid methods use Midtrans gateway
enum PaymentMethod {
  // Midtrans-processed methods (instant payment)
  qris,           // QRIS code
  gopay,          // GoPay e-wallet
  shopeePay,      // ShopeePay e-wallet
  dana,           // DANA e-wallet
  bcaVa,          // BCA Virtual Account
  mandiriVa,      // Mandiri Bill Key
  bniVa,          // BNI Virtual Account
  permataVa,      // Permata Virtual Account
  otherVa,        // Other bank VAs

  // Manual methods (require upload proof)
  bankTransfer,   // Manual bank transfer with confirmation

  creditCard,     // Credit card (via Midtrans)

  free,           // Free ticket (no payment)
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
        return 'Transfer Bank (Manual)';
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
}
