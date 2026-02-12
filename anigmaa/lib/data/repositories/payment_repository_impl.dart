import 'package:dio/dio.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../core/api/dio_client.dart';

import '../../core/services/auth_service.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final DioClient _dioClient;

  final AuthService _authService;

  PaymentRepositoryImpl(this._dioClient, this._authService);

  @override
  Future<Map<String, dynamic>> initiatePayment({
    required String eventId,
    required int amount,
    required String paymentMethod,
    String? firstName,
    String? lastName,
    String? email,
    String? itemName,
  }) async {
    try {
      // Backend expects Midtrans format
      // Path should be /payments/initiate because DioClient base URL already has /api/v1

      final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

      // Get user data from AuthService
      final userEmail = email ?? _authService.userEmail ?? 'user@anigmaa.com';
      final userName = firstName ?? _authService.userName ?? 'User';

      final Map<String, dynamic> requestData = {
        'order_id': orderId,
        'amount': amount.toDouble(),
        'first_name': userName,
        'email': userEmail,
        'item_name': itemName ?? 'Event Ticket',
        'item_id': eventId,
      };

      if (lastName != null && lastName.isNotEmpty) {
        requestData['last_name'] = lastName;
      }

      // Do not include phone if empty/null
      // requestData['phone'] = '';

      print('PaymentRepository: Initiating payment with data: $requestData');

      final response = await _dioClient.post(
        '/payments/initiate',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final redirectUrl =
            data['redirect_url'] ?? data['payment_url'] ?? data['snap_url'];
        final token = data['token'] ?? data['transaction_id'];

        print('PaymentRepository: Parsed redirect_url: $redirectUrl');
        print('PaymentRepository: Parsed token: $token');

        return {
          'payment_url': redirectUrl,
          'transaction_id': token,
          'payment_token': token,
        };
      } else {
        throw Exception('Failed to initiate payment');
      }
    } on DioException catch (e) {
      print('PaymentRepository: DioError: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('PaymentRepository: Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> processPayment({
    required String transactionId,
    required String paymentToken,
  }) async {
    // With Midtrans Snap, processing is handled by the SDK.
    // This method might be used for other gateways or manual updates,
    // but for now we just return mock success or use checkPaymentStatus.
    return {'status': 'pending'};
  }

  @override
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      // Backend expects POST /payments/status with order_id (which we might pass as transactionId here)
      // or we need to separate transactionId (token) vs order_id.
      // Assuming transactionId passed here IS the order_id for simplicity (as usually we track order_id).
      final response = await _dioClient.post(
        '/payments/status',
        data: {'order_id': transactionId},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to check payment status');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<void> cancelPayment(String transactionId) async {
    // Not implemented in backend yet
    throw UnimplementedError('Cancel payment not implemented');
  }

  @override
  Future<List<PaymentMethodInfo>> getAvailablePaymentMethods() async {
    // Managed by Midtrans Snap UI
    return [];
  }

  @override
  Future<String> generateQRCode(String transactionId) async {
    // Managed by Midtrans Snap UI
    return '';
  }

  @override
  Future<Map<String, dynamic>> confirmManualTransfer({
    required String transactionId,
    required String proofImageUrl,
  }) async {
    // Not part of Midtrans flow
    throw UnimplementedError('Manual transfer not implemented');
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return Exception(
              'Invalid payment details: ${e.response?.data['message'] ?? ''}',
            );
          case 401:
            return Exception('Unauthorized');
          case 404:
            return Exception('Payment endpoint not found');
          case 422:
            return Exception('Payment failed: ${e.response?.data['message']}');
          case 500:
            return Exception('Payment server error');
          default:
            return Exception('HTTP Error: $statusCode');
        }
      case DioExceptionType.cancel:
        return Exception('Payment cancelled');
      case DioExceptionType.connectionError:
        return Exception('Connection error');
      case DioExceptionType.unknown:
        return Exception('Network error');
      default:
        return Exception('Unknown error');
    }
  }
}
