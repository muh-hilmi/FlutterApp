import 'package:equatable/equatable.dart';
import 'user.dart';
import 'event.dart';

class CommunityPost extends Equatable {
  final String id;
  final String communityId;
  final User author;
  final String content;
  final List<String> imageUrls;
  final Event? attachedEvent;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
  final bool isPinned;

  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.author,
    required this.content,
    this.imageUrls = const [],
    this.attachedEvent,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
    this.isPinned = false,
  });

  CommunityPost copyWith({
    String? id,
    String? communityId,
    User? author,
    String? content,
    List<String>? imageUrls,
    Event? attachedEvent,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? commentCount,
    bool? isLikedByCurrentUser,
    bool? isPinned,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      author: author ?? this.author,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      attachedEvent: attachedEvent ?? this.attachedEvent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        author,
        content,
        imageUrls,
        attachedEvent,
        createdAt,
        updatedAt,
        likeCount,
        commentCount,
        isLikedByCurrentUser,
        isPinned,
      ];
}
