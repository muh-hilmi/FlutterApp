import 'package:equatable/equatable.dart';

/// Ticket entity representing an event ticket purchase
///
/// Contains attendance code for simple check-in system
/// Supports both free reservations and paid tickets
class Ticket extends Equatable {
  final String id;
  final String userId;
  final String eventId;
  final String attendanceCode; // 4-character code (e.g., "A3F7")
  final double pricePaid; // 0 for free events
  final DateTime purchasedAt;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final TicketStatus status;

  // Event details from TicketWithDetails
  final String? eventTitle;
  final DateTime? eventStartTime;
  final String? eventLocation;

  const Ticket({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.attendanceCode,
    required this.pricePaid,
    required this.purchasedAt,
    this.isCheckedIn = false,
    this.checkedInAt,
    this.status = TicketStatus.active,
    this.eventTitle,
    this.eventStartTime,
    this.eventLocation,
  });

  /// Check if this is a free ticket
  bool get isFree => pricePaid == 0;

  /// Check if ticket is valid for use
  bool get isValid => status == TicketStatus.active && !isCheckedIn;

  @override
  List<Object?> get props => [
        id,
        userId,
        eventId,
        attendanceCode,
        pricePaid,
        purchasedAt,
        isCheckedIn,
        checkedInAt,
        status,
        eventTitle,
        eventStartTime,
        eventLocation,
      ];

  Ticket copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? attendanceCode,
    double? pricePaid,
    DateTime? purchasedAt,
    bool? isCheckedIn,
    DateTime? checkedInAt,
    TicketStatus? status,
    String? eventTitle,
    DateTime? eventStartTime,
    String? eventLocation,
  }) {
    return Ticket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      attendanceCode: attendanceCode ?? this.attendanceCode,
      pricePaid: pricePaid ?? this.pricePaid,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      status: status ?? this.status,
      eventTitle: eventTitle ?? this.eventTitle,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventLocation: eventLocation ?? this.eventLocation,
    );
  }

  @override
  String toString() {
    return 'Ticket(id: $id, eventId: $eventId, code: $attendanceCode, '
        'price: $pricePaid, status: $status, checkedIn: $isCheckedIn)';
  }
}

/// Ticket status enumeration
enum TicketStatus {
  active,      // Valid ticket
  cancelled,   // User cancelled
  refunded,    // Payment refunded
  expired,     // Event has passed
}

extension TicketStatusExtension on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.active:
        return 'Active';
      case TicketStatus.cancelled:
        return 'Cancelled';
      case TicketStatus.refunded:
        return 'Refunded';
      case TicketStatus.expired:
        return 'Expired';
    }
  }

  bool get isUsable => this == TicketStatus.active;
}
