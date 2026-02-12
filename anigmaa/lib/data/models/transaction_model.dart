import '../../domain/entities/transaction.dart';

/// Transaction model for data layer
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.ticketId,
    required super.eventId,
    required super.eventName,
    required super.amount,
    super.adminFee,
    required super.status,
    required super.paymentMethod,
    super.paymentProof,
    super.virtualAccountNumber,
    required super.createdAt,
    super.paidAt,
    super.expiredAt,
    super.metadata,
  });

  /// Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      eventId: json['event_id'] ?? '',
      eventName: json['event_name'] ?? 'Unknown Event',
      amount: (json['amount'] ?? 0).toDouble(),
      adminFee: (json['admin_fee'] ?? 0).toDouble(),
      status: _parseStatus(json['status']),
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      paymentProof: json['payment_proof'],
      virtualAccountNumber: json['virtual_account_number'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'])
          : null,
      expiredAt: json['expired_at'] != null
          ? DateTime.parse(json['expired_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ticket_id': ticketId,
      'event_id': eventId,
      'event_name': eventName,
      'amount': amount,
      'admin_fee': adminFee,
      'status': _statusToString(status),
      'payment_method': _paymentMethodToString(paymentMethod),
      'payment_proof': paymentProof,
      'virtual_account_number': virtualAccountNumber,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'expired_at': expiredAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Convert to entity
  Transaction toEntity() {
    return Transaction(
      id: id,
      userId: userId,
      ticketId: ticketId,
      eventId: eventId,
      eventName: eventName,
      amount: amount,
      adminFee: adminFee,
      status: status,
      paymentMethod: paymentMethod,
      paymentProof: paymentProof,
      virtualAccountNumber: virtualAccountNumber,
      createdAt: createdAt,
      paidAt: paidAt,
      expiredAt: expiredAt,
      metadata: metadata,
    );
  }

  /// Create from entity
  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      userId: transaction.userId,
      ticketId: transaction.ticketId,
      eventId: transaction.eventId,
      eventName: transaction.eventName,
      amount: transaction.amount,
      adminFee: transaction.adminFee,
      status: transaction.status,
      paymentMethod: transaction.paymentMethod,
      paymentProof: transaction.paymentProof,
      virtualAccountNumber: transaction.virtualAccountNumber,
      createdAt: transaction.createdAt,
      paidAt: transaction.paidAt,
      expiredAt: transaction.expiredAt,
      metadata: transaction.metadata,
    );
  }

  /// Parse status from string
  static TransactionStatus _parseStatus(dynamic status) {
    if (status == null) return TransactionStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'pending':
        return TransactionStatus.pending;
      case 'processing':
        return TransactionStatus.processing;
      case 'success':
      case 'completed':
        return TransactionStatus.success;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'expired':
        return TransactionStatus.expired;
      case 'refunded':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.pending;
    }
  }

  /// Convert status to string
  static String _statusToString(TransactionStatus status) {
    return status.toString().split('.').last;
  }

  /// Parse payment method from string
  static PaymentMethod _parsePaymentMethod(dynamic method) {
    if (method == null) return PaymentMethod.free;

    final methodStr = method.toString().toLowerCase();

    // QRIS
    if (methodStr.contains('qris')) {
      return PaymentMethod.qris;
    }
    // E-wallets
    if (methodStr.contains('gopay')) {
      return PaymentMethod.gopay;
    }
    if (methodStr.contains('shopee')) {
      return PaymentMethod.shopeePay;
    }
    if (methodStr.contains('dana')) {
      return PaymentMethod.dana;
    }
    // Virtual Accounts
    if (methodStr.contains('bca') && methodStr.contains('va')) {
      return PaymentMethod.bcaVa;
    }
    if (methodStr.contains('mandiri')) {
      return PaymentMethod.mandiriVa;
    }
    if (methodStr.contains('bni') && methodStr.contains('va')) {
      return PaymentMethod.bniVa;
    }
    if (methodStr.contains('permata')) {
      return PaymentMethod.permataVa;
    }
    if (methodStr.contains('va') || methodStr.contains('virtual')) {
      return PaymentMethod.otherVa;
    }
    // Bank transfer (manual)
    if (methodStr.contains('bank') || methodStr.contains('transfer')) {
      return PaymentMethod.bankTransfer;
    }
    // Credit card
    if (methodStr.contains('credit') || methodStr.contains('card')) {
      return PaymentMethod.creditCard;
    }
    // Free
    if (methodStr.contains('free')) {
      return PaymentMethod.free;
    }
    return PaymentMethod.free;
  }

  /// Convert payment method to string
  static String _paymentMethodToString(PaymentMethod method) {
    return method.toString().split('.').last;
  }

  @override
  TransactionModel copyWith({
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
    return TransactionModel(
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
}
