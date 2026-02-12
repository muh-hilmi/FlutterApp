import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/midtrans_payment_model.dart';

/// Payment service for Midtrans integration
class MidtransPaymentService {
  final String baseUrl;
  final String? authToken;
  final Logger _logger = Logger();

  MidtransPaymentService({
    required this.baseUrl,
    this.authToken,
  });

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Initiate payment and get Snap token
  Future<SnapTokenResponse> initiatePayment(PaymentInitRequest request) async {
    try {
      _logger.i('Initiating payment for order: ${request.orderId}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/payments/initiate'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final apiResponse = ApiResponse<SnapTokenResponse>.fromJson(
          jsonDecode(response.body),
          (data) => SnapTokenResponse.fromJson(data),
        );

        if (apiResponse.success && apiResponse.data != null) {
          _logger.i('Snap token obtained successfully');
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error initiating payment: $e');
      rethrow;
    }
  }

  /// Check payment status
  Future<PaymentStatusResponse> checkPaymentStatus(String orderId) async {
    try {
      _logger.i('Checking payment status for order: $orderId');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/payments/status'),
        headers: _headers,
        body: jsonEncode({'order_id': orderId}),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<PaymentStatusResponse>.fromJson(
          jsonDecode(response.body),
          (data) => PaymentStatusResponse.fromJson(data),
        );

        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error checking payment status: $e');
      rethrow;
    }
  }

  /// Get Midtrans client key (for initialization)
  Future<String> getClientKey() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/payments/client-key'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['client_key'] ?? '';
      }
      throw Exception('Failed to get client key');
    } catch (e) {
      _logger.e('Error getting client key: $e');
      rethrow;
    }
  }
}
