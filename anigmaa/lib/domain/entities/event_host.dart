class EventHost {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final bool isVerified;
  final double rating;
  final int eventsHosted;

  const EventHost({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    this.isVerified = false,
    this.rating = 0.0,
    this.eventsHosted = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventHost &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}