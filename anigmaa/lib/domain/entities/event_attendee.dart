import 'package:equatable/equatable.dart';

/// Entity representing an event attendee for host view
/// Contains ticket and check-in information
class EventAttendee extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final String ticketType;
  final String ticketId;
  final bool checkedIn;
  final DateTime? checkedInAt;
  final DateTime purchasedAt;

  const EventAttendee({
    required this.id,
    required this.name,
    this.avatar,
    required this.ticketType,
    required this.ticketId,
    this.checkedIn = false,
    this.checkedInAt,
    required this.purchasedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        avatar,
        ticketType,
        ticketId,
        checkedIn,
        checkedInAt,
        purchasedAt,
      ];

  EventAttendee copyWith({
    String? id,
    String? name,
    String? avatar,
    String? ticketType,
    String? ticketId,
    bool? checkedIn,
    DateTime? checkedInAt,
    DateTime? purchasedAt,
  }) {
    return EventAttendee(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      ticketType: ticketType ?? this.ticketType,
      ticketId: ticketId ?? this.ticketId,
      checkedIn: checkedIn ?? this.checkedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
    );
  }

  /// Get check-in status text
  String get checkInStatusText {
    if (checkedIn) {
      return 'Checked In';
    }
    return 'Not Checked In';
  }

  /// Get formatted check-in time
  String? get formattedCheckInTime {
    if (checkedInAt == null) return null;
    final hours = checkedInAt!.hour.toString().padLeft(2, '0');
    final minutes = checkedInAt!.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
