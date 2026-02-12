import 'package:equatable/equatable.dart';

enum InteractionType {
  like,
  repost,
  bookmark,
  share,
}

class Interaction extends Equatable {
  final String id;
  final String userId;
  final String targetId; // post ID or comment ID
  final InteractionType type;
  final DateTime createdAt;

  // For reposts with quote/comment
  final String? quoteContent;

  const Interaction({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.type,
    required this.createdAt,
    this.quoteContent,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        targetId,
        type,
        createdAt,
        quoteContent,
      ];
}
