class Review {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String eventId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;
  final int helpfulCount;
  final bool isVerifiedAttendee;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.eventId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
    this.helpfulCount = 0,
    this.isVerifiedAttendee = false,
  });

  Review copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? eventId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    List<String>? images,
    int? helpfulCount,
    bool? isVerifiedAttendee,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      eventId: eventId ?? this.eventId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isVerifiedAttendee: isVerifiedAttendee ?? this.isVerifiedAttendee,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}