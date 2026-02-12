class EventLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? venue;

  const EventLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.venue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLocation &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      name.hashCode ^
      address.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}