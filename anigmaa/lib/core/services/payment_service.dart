import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import '../../domain/entities/ticket_transaction.dart';

/// Payment service for Midtrans integration
import '../../injection_container.dart';
import '../../presentation/bloc/payment/payment_bloc.dart';

class PaymentService {
  MidtransSDK? _midtrans;
  bool _isInitialized = false;

  /// Initialize payment service
  Future<void> initialize({
    required String clientKey,
    required String merchantBaseUrl,
  }) async {
    try {
      _midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: clientKey,
          merchantBaseUrl: merchantBaseUrl,
          colorTheme: ColorTheme(
            colorPrimary: const Color(0xFFBBC863),
            colorPrimaryDark: const Color(0xFF9AA850),
            colorSecondary: const Color(0xFFBBC863),
          ),
        ),
      );

      _midtrans?.setTransactionFinishedCallback((TransactionResult result) {
        // Dispatch transaction result to PaymentBloc
        print('Transaction Result: $result');
        final status = result.status.toString().toLowerCase();
        if (status == 'success' || status == 'settlement') {
          sl<PaymentBloc>().add(
            PaymentSuccess(
              transactionId: result.transactionId ?? '',
              // receiptUrl: result.pdfUrl, // Unavailable in default SDK model
            ),
          );
        } else {
          // Use status as fallback message since statusMessage is unavailable
          sl<PaymentBloc>().add(PaymentFailed(result.status.toString()));
        }
      });

      _isInitialized = true;
      print('PaymentService initialized successfully');
    } catch (e) {
      print('Failed to initialize payment service: $e');
      // Non-fatal, as we might already be initialized or it might retry
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initiate payment UI Flow using Snap Token
  Future<void> startPayment(String snapToken) async {
    print('PaymentService.startPayment called with token: $snapToken');
    if (!_isInitialized || _midtrans == null) {
      print('PaymentService not initialized or _midtrans is null');
      throw Exception('PaymentService not initialized');
    }

    try {
      print('Invoking _midtrans.startPaymentUiFlow...');
      await _midtrans!.startPaymentUiFlow(token: snapToken);
      print('_midtrans.startPaymentUiFlow invoked successfully');
    } catch (e) {
      print('Exception in startPaymentUiFlow: $e');
      throw Exception('Failed to start payment UI: $e');
    }
  }

  /// Process payment for event ticket (Legacy/Web flow support or Mock)
  Future<PaymentResult> processPayment({
    required String eventId,
    required String userId,
    required String ticketId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  }) async {
    // This method seems to be from the old mock implementation.
    // For SDK flow, we just need startPayment(token).
    // Keeping this for compatibility if needed, but returning failed or mock.
    throw UnimplementedError("Use startPayment(token) for Midtrans SDK flow");
  }

  /// Process free ticket (no payment required)
  Future<PaymentResult> processFreeTicket({
    required String eventId,
    required String userId,
    required String ticketId,
  }) async {
    // Keep existing free ticket logic if needed, or move to repository
    return PaymentResult(
      success: true,
      transactionId: 'FREE-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Free ticket reserved',
      status: TransactionStatus.completed,
      paymentType: 'free',
    );
  }

  void dispose() {
    _midtrans?.removeTransactionFinishedCallback();
    _isInitialized = false;
  }
}

/// Payment result wrapper
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;
  final TransactionStatus status;
  final String? paymentType;
  final Map<String, dynamic>? response;
  final String? error;
  final String? redirectUrl;
  final String? token;

  const PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
    required this.status,
    this.paymentType,
    this.response,
    this.error,
    this.redirectUrl,
    this.token,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, transactionId: $transactionId, '
        'message: $message, status: $status)';
  }
}
