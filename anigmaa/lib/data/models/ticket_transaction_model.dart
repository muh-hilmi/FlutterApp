import 'dart:convert';
import '../../domain/entities/ticket_transaction.dart';

/// Data model for TicketTransaction with JSON serialization
class TicketTransactionModel {
  final String id;
  final String ticketId;
  final String userId;
  final String eventId;
  final double amount;
  final String status;
  final String paymentMethod;
  final String? paymentGatewayId;
  final String? paymentGatewayResponse;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? failureReason;

  const TicketTransactionModel({
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

  /// Convert to domain entity
  TicketTransaction toEntity() {
    return TicketTransaction(
      id: id,
      ticketId: ticketId,
      userId: userId,
      eventId: eventId,
      amount: amount,
      status: _parseTransactionStatus(status),
      paymentMethod: _parsePaymentMethod(paymentMethod),
      paymentGatewayId: paymentGatewayId,
      paymentGatewayResponse: paymentGatewayResponse,
      createdAt: createdAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      failureReason: failureReason,
    );
  }

  /// Create from domain entity
  factory TicketTransactionModel.fromEntity(TicketTransaction transaction) {
    return TicketTransactionModel(
      id: transaction.id,
      ticketId: transaction.ticketId,
      userId: transaction.userId,
      eventId: transaction.eventId,
      amount: transaction.amount,
      status: _transactionStatusToString(transaction.status),
      paymentMethod: _paymentMethodToString(transaction.paymentMethod),
      paymentGatewayId: transaction.paymentGatewayId,
      paymentGatewayResponse: transaction.paymentGatewayResponse,
      createdAt: transaction.createdAt,
      completedAt: transaction.completedAt,
      cancelledAt: transaction.cancelledAt,
      failureReason: transaction.failureReason,
    );
  }

  /// Create from JSON
  factory TicketTransactionModel.fromJson(Map<String, dynamic> json) {
    return TicketTransactionModel(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentGatewayId: json['paymentGatewayId'] as String?,
      paymentGatewayResponse: json['paymentGatewayResponse'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      failureReason: json['failureReason'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'eventId': eventId,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentGatewayId': paymentGatewayId,
      'paymentGatewayResponse': paymentGatewayResponse,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  /// Parse TransactionStatus from string
  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'refunded':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.pending;
    }
  }

  /// Convert TransactionStatus to string
  static String _transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.cancelled:
        return 'cancelled';
      case TransactionStatus.refunded:
        return 'refunded';
    }
  }

  /// Parse PaymentMethod from string
  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'gopay':
        return PaymentMethod.gopay;
      case 'shopeepay':
      case 'shopee':
        return PaymentMethod.shopeePay;
      case 'dana':
        return PaymentMethod.dana;
      case 'qris':
        return PaymentMethod.qris;
      case 'bank_transfer':
      case 'banktransfer':
        return PaymentMethod.bankTransfer;
      case 'bca_va':
      case 'bcava':
        return PaymentMethod.bcaVa;
      case 'mandiri_va':
      case 'mandiriva':
        return PaymentMethod.mandiriVa;
      case 'bni_va':
      case 'bniva':
        return PaymentMethod.bniVa;
      case 'permata_va':
      case 'permatava':
        return PaymentMethod.permataVa;
      case 'credit_card':
      case 'creditcard':
        return PaymentMethod.creditCard;
      case 'free':
        return PaymentMethod.free;
      default:
        return PaymentMethod.free;
    }
  }

  /// Convert PaymentMethod to string
  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.gopay:
        return 'gopay';
      case PaymentMethod.shopeePay:
        return 'shopeepay';
      case PaymentMethod.dana:
        return 'dana';
      case PaymentMethod.qris:
        return 'qris';
      case PaymentMethod.bcaVa:
        return 'bca_va';
      case PaymentMethod.mandiriVa:
        return 'mandiri_va';
      case PaymentMethod.bniVa:
        return 'bni_va';
      case PaymentMethod.permataVa:
        return 'permata_va';
      case PaymentMethod.otherVa:
        return 'other_va';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.free:
        return 'free';
    }
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory TicketTransactionModel.fromJsonString(String jsonString) {
    return TicketTransactionModel.fromJson(json.decode(jsonString));
  }
}
