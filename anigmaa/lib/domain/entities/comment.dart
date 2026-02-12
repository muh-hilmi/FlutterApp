import 'package:equatable/equatable.dart';
import 'user.dart';
import '../../core/utils/logger.dart';

class Comment extends Equatable {
  final String id;
  final String postId;
  final User author;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;

  // For nested comments (replies)
  final String? parentCommentId;
  final int repliesCount;

  // Engagement
  final int likesCount;
  final bool isLikedByCurrentUser;

  // Mentions in comment
  final List<String> mentions; // user IDs

  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
    this.editedAt,
    this.parentCommentId,
    this.repliesCount = 0,
    this.likesCount = 0,
    this.isLikedByCurrentUser = false,
    this.mentions = const [],
  });

  bool get isReply => parentCommentId != null;

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Backend should send author as nested object (snake_case fields)
    // Temporary fallback for backward compatibility
    final User author;
    if (json['author'] != null && json['author'] is Map) {
      final authorData = json['author'] as Map<String, dynamic>;
      final avatarUrl = authorData['avatar_url'] ?? authorData['avatar'];

      // Debug logging
      logger.d('[Comment] Parsing author: ${authorData['name']}, avatar_url: $avatarUrl');

      author = User(
        id: authorData['id'] as String,
        email: authorData['email'] as String? ?? '',
        name: authorData['name'] as String,
        bio: authorData['bio'] as String?,
        avatar: avatarUrl as String?,
        isVerified: authorData['is_verified'] as bool? ?? false,
        createdAt: authorData['created_at'] != null
            ? DateTime.parse(authorData['created_at'] as String)
            : DateTime.now(),
        settings: const UserSettings(),
        stats: const UserStats(),
        privacy: const UserPrivacy(),
      );
    } else {
      // Temporary fallback for legacy flat structure
      final avatarUrl = json['author_avatar_url'] ?? json['author_avatar'];

      logger.d('[Comment] Fallback parsing author: ${json['author_name']}, avatar_url: $avatarUrl');

      author = User(
        id: json['author_id'] as String,
        email: '',
        name: json['author_name'] as String,
        bio: '',
        avatar: avatarUrl as String?,
        isVerified: json['author_is_verified'] as bool? ?? false,
        createdAt: DateTime.now(),
        settings: const UserSettings(),
        stats: const UserStats(),
        privacy: const UserPrivacy(),
      );
    }

    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      author: author,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      parentCommentId: json['parent_comment_id'] as String?,
      repliesCount: json['replies_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      isLikedByCurrentUser: json['is_liked_by_user'] as bool? ?? false,
      mentions: List<String>.from(json['mentions'] ?? []),
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    User? author,
    String? content,
    DateTime? createdAt,
    DateTime? editedAt,
    String? parentCommentId,
    int? repliesCount,
    int? likesCount,
    bool? isLikedByCurrentUser,
    List<String>? mentions,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      repliesCount: repliesCount ?? this.repliesCount,
      likesCount: likesCount ?? this.likesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      mentions: mentions ?? this.mentions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        author,
        content,
        createdAt,
        editedAt,
        parentCommentId,
        repliesCount,
        likesCount,
        isLikedByCurrentUser,
        mentions,
      ];
}
