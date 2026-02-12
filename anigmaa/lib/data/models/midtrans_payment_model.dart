import 'package:equatable/equatable.dart';

/// Payment initiation request
class PaymentInitRequest extends Equatable {
  final String orderId;
  final double amount;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String itemName;
  final String itemId;

  const PaymentInitRequest({
    required this.orderId,
    required this.amount,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.itemName,
    required this.itemId,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'amount': amount,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      if (phone != null) 'phone': phone,
      'item_name': itemName,
      'item_id': itemId,
    };
  }

  @override
  List<Object?> get props => [orderId, amount, firstName, lastName, email];
}

/// Snap token response from backend
class SnapTokenResponse extends Equatable {
  final String token;
  final String redirectUrl;

  const SnapTokenResponse({
    required this.token,
    required this.redirectUrl,
  });

  factory SnapTokenResponse.fromJson(Map<String, dynamic> json) {
    return SnapTokenResponse(
      token: json['token'] ?? '',
      redirectUrl: json['redirect_url'] ?? '',
    );
  }

  @override
  List<Object?> get props => [token, redirectUrl];
}

/// Payment transaction status
enum TransactionStatus {
  unauthorized,
  capture,
  settlement,
  pending,
  deny,
  cancel,
  expire,
  refund,
  partialRefund,
  authorize,
}

extension TransactionStatusExtension on TransactionStatus {
  String get value {
    switch (this) {
      case TransactionStatus.unauthorized:
        return 'unauthorized';
      case TransactionStatus.capture:
        return 'capture';
      case TransactionStatus.settlement:
        return 'settlement';
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.deny:
        return 'deny';
      case TransactionStatus.cancel:
        return 'cancel';
      case TransactionStatus.expire:
        return 'expire';
      case TransactionStatus.refund:
        return 'refund';
      case TransactionStatus.partialRefund:
        return 'partial_refund';
      case TransactionStatus.authorize:
        return 'authorize';
    }
  }

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }

  bool get isSuccess =>
      this == TransactionStatus.settlement ||
      this == TransactionStatus.capture ||
      this == TransactionStatus.authorize;

  bool get isPending => this == TransactionStatus.pending;

  bool get isFailed =>
      this == TransactionStatus.deny ||
      this == TransactionStatus.cancel ||
      this == TransactionStatus.expire ||
      this == TransactionStatus.unauthorized;

  bool get isRefunded =>
      this == TransactionStatus.refund ||
      this == TransactionStatus.partialRefund;
}

/// Payment status response
class PaymentStatusResponse extends Equatable {
  final String orderId;
  final String transactionId;
  final String grossAmount;
  final String currency;
  final String paymentType;
  final TransactionStatus transactionStatus;
  final String transactionTime;
  final String? fraudStatus;

  const PaymentStatusResponse({
    required this.orderId,
    required this.transactionId,
    required this.grossAmount,
    required this.currency,
    required this.paymentType,
    required this.transactionStatus,
    required this.transactionTime,
    this.fraudStatus,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      orderId: json['order_id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      grossAmount: json['gross_amount'] ?? '',
      currency: json['currency'] ?? 'IDR',
      paymentType: json['payment_type'] ?? '',
      transactionStatus: TransactionStatusExtension.fromString(
        json['transaction_status'] ?? 'pending',
      ),
      transactionTime: json['transaction_time'] ?? '',
      fraudStatus: json['fraud_status'],
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        transactionId,
        transactionStatus,
        paymentType,
      ];
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['status'] == 'success' || json['success'] == true,
      message: json['message'] ?? '',
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'],
    );
  }
}
