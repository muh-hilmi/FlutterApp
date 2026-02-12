import 'package:equatable/equatable.dart';
import 'user.dart';
import '../../core/utils/logger.dart';

class QnA extends Equatable {
  final String id;
  final String eventId;
  final String question;
  final String? answer;
  final User askedBy;
  final User? answeredBy;
  final DateTime askedAt;
  final DateTime? answeredAt;
  final int upvotes;
  final bool isUpvotedByCurrentUser;

  const QnA({
    required this.id,
    required this.eventId,
    required this.question,
    this.answer,
    required this.askedBy,
    this.answeredBy,
    required this.askedAt,
    this.answeredAt,
    this.upvotes = 0,
    this.isUpvotedByCurrentUser = false,
  });

  bool get isAnswered => answer != null;

  factory QnA.fromJson(Map<String, dynamic> json) {
    logger.d('[QnA.fromJson] Parsing Q&A: ${json['id']}');
    logger.d('[QnA.fromJson] Full JSON: $json');

    return QnA(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      askedBy: User(
        id: json['askedBy']['id'] as String,
        email: json['askedBy']['email'] as String? ?? '',
        name: json['askedBy']['name'] as String,
        bio: null, // Backend UserBasicInfo doesn't include bio
        avatar: json['askedBy']['avatar'] as String?,
        createdAt: DateTime.parse(json['askedBy']['createdAt'] as String),
        settings: const UserSettings(),
        stats: const UserStats(),
        privacy: const UserPrivacy(),
      ),
      answeredBy: json['answeredBy'] != null
          ? User(
              id: json['answeredBy']['id'] as String,
              email: json['answeredBy']['email'] as String? ?? '',
              name: json['answeredBy']['name'] as String,
              bio: null, // Backend UserBasicInfo doesn't include bio
              avatar: json['answeredBy']['avatar'] as String?,
              createdAt: DateTime.parse(json['answeredBy']['createdAt'] as String),
              settings: const UserSettings(),
              stats: const UserStats(),
              privacy: const UserPrivacy(),
            )
          : null,
      askedAt: DateTime.parse(json['askedAt'] as String),
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
      upvotes: json['upvotes'] as int? ?? 0,
      isUpvotedByCurrentUser: json['isUpvotedByCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'question': question,
      if (answer != null) 'answer': answer,
      'askedBy': {
        'id': askedBy.id,
        'email': askedBy.email,
        'name': askedBy.name,
        if (askedBy.bio != null) 'bio': askedBy.bio,
        if (askedBy.avatar != null) 'avatar': askedBy.avatar,
        'createdAt': askedBy.createdAt.toIso8601String(),
      },
      if (answeredBy != null)
        'answeredBy': {
          'id': answeredBy!.id,
          'email': answeredBy!.email,
          'name': answeredBy!.name,
          if (answeredBy!.bio != null) 'bio': answeredBy!.bio,
          if (answeredBy!.avatar != null) 'avatar': answeredBy!.avatar,
          'createdAt': answeredBy!.createdAt.toIso8601String(),
        },
      'askedAt': askedAt.toIso8601String(),
      if (answeredAt != null) 'answeredAt': answeredAt!.toIso8601String(),
      'upvotes': upvotes,
      'isUpvotedByCurrentUser': isUpvotedByCurrentUser,
    };
  }

  QnA copyWith({
    String? id,
    String? eventId,
    String? question,
    String? answer,
    User? askedBy,
    User? answeredBy,
    DateTime? askedAt,
    DateTime? answeredAt,
    int? upvotes,
    bool? isUpvotedByCurrentUser,
  }) {
    return QnA(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      askedBy: askedBy ?? this.askedBy,
      answeredBy: answeredBy ?? this.answeredBy,
      askedAt: askedAt ?? this.askedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      upvotes: upvotes ?? this.upvotes,
      isUpvotedByCurrentUser: isUpvotedByCurrentUser ?? this.isUpvotedByCurrentUser,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        question,
        answer,
        askedBy,
        answeredBy,
        askedAt,
        answeredAt,
        upvotes,
        isUpvotedByCurrentUser,
      ];
}
