import 'dart:convert';

class ScanResultModel {
  final String type;
  final String? userId;
  final String? eventId;
  final Map<String, dynamic>? additionalData;

  ScanResultModel({
    required this.type,
    this.userId,
    this.eventId,
    this.additionalData,
  });

  factory ScanResultModel.fromString(String qrData) {
    try {
      // Try to parse as JSON first
      final Map<String, dynamic> data = json.decode(qrData);
      
      return ScanResultModel(
        type: data['type'] ?? 'unknown',
        userId: data['user_id'],
        eventId: data['event_id'],
        additionalData: data,
      );
    } catch (e) {
      // Fallback to simple string parsing for backward compatibility
      if (qrData.startsWith('profile:')) {
        return ScanResultModel(
          type: 'profile',
          userId: qrData.substring(8), // Remove 'profile:' prefix
        );
      } else if (qrData.startsWith('event:')) {
        return ScanResultModel(
          type: 'event',
          eventId: qrData.substring(6), // Remove 'event:' prefix
        );
      }
      
      // Return unknown type if parsing fails
      return ScanResultModel(type: 'unknown');
    }
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      type: json['type'] ?? 'unknown',
      userId: json['user_id'],
      eventId: json['event_id'],
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'user_id': userId,
      'event_id': eventId,
      if (additionalData != null) ...additionalData!,
    };
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
