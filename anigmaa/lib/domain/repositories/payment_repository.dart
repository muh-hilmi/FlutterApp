abstract class PaymentRepository {
  /// Initiate payment for an event
  Future<Map<String, dynamic>> initiatePayment({
    required String eventId,
    required int amount,
    required String paymentMethod,
    String? firstName,
    String? lastName,
    String? email,
    String? itemName,
  });

  /// Process payment with transaction token
  Future<Map<String, dynamic>> processPayment({
    required String transactionId,
    required String paymentToken,
  });

  /// Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId);

  /// Cancel payment
  Future<void> cancelPayment(String transactionId);

  /// Get available payment methods
  Future<List<PaymentMethodInfo>> getAvailablePaymentMethods();

  /// Generate QR code for payment
  Future<String> generateQRCode(String transactionId);

  /// Process manual transfer confirmation
  Future<Map<String, dynamic>> confirmManualTransfer({
    required String transactionId,
    required String proofImageUrl,
  });
}

/// Payment method info returned from API
class PaymentMethodInfo {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final bool isEnabled;
  final int fee;

  const PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.isEnabled = true,
    this.fee = 0,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String,
      isEnabled: json['is_enabled'] as bool? ?? true,
      fee: json['fee'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'is_enabled': isEnabled,
      'fee': fee,
    };
  }
}