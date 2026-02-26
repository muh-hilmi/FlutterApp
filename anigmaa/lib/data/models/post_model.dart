import '../../domain/entities/post.dart';
import '../../domain/entities/event.dart';
import '../../core/utils/app_logger.dart';
import 'user_model.dart';
import 'event_model.dart';

/// Data model for Post entity following Clean Architecture principles
/// Handles JSON serialization/deserialization and data transformations
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.author,
    required super.content,
    required super.type,
    super.imageUrls = const [],
    super.attachedEvent,
    super.poll,
    required super.createdAt,
    super.editedAt,
    super.likesCount = 0,
    super.commentsCount = 0,
    super.repostsCount = 0,
    super.sharesCount = 0,
    super.isLikedByCurrentUser = false,
    super.isRepostedByCurrentUser = false,
    super.isBookmarked = false,
    super.originalPost,
    super.repostAuthor,
    super.repostedAt,
    super.hashtags = const [],
    super.mentions = const [],
    super.visibility = PostVisibility.public,
  });

  /// Creates PostModel from JSON response
  ///
  /// Handles both structured author objects and legacy author_id format
  factory PostModel.fromJson(Map<String, dynamic> json) {
    final logger = AppLogger();

    // Parse author information
    final author = _parseAuthor(json);

    try {
      return PostModel(
        id: json['id'] as String? ?? '',
        author: author,
        content: json['content'] as String? ?? '',
        type: _parsePostType(json['type']),
        imageUrls: List<String>.from(json['image_urls'] ?? []),
        attachedEvent: _parseAttachedEvent(json),
        poll: json['poll'] != null ? PollModel.fromJson(json['poll'] as Map<String, dynamic>) : null,
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        editedAt: _parseDateTime(json['updated_at']),
        likesCount: json['likes_count'] as int? ?? 0,
        commentsCount: json['comments_count'] as int? ?? 0,
        repostsCount: json['reposts_count'] as int? ?? 0,
        sharesCount: json['shares_count'] as int? ?? 0,
        isLikedByCurrentUser: _parseBool(json['is_liked_by_current_user']) ?? _parseBool(json['is_liked_by_user']) ?? false,
        isRepostedByCurrentUser: _parseBool(json['is_reposted_by_current_user']) ?? _parseBool(json['is_reposted_by_user']) ?? false,
        isBookmarked: _parseBool(json['is_bookmarked']) ?? _parseBool(json['is_bookmarked_by_user']) ?? false,
        originalPost: json['original_post'] != null
            ? PostModel.fromJson(json['original_post'] as Map<String, dynamic>)
            : null,
        repostAuthor: json['repost_author'] != null
            ? UserModel.fromJson(json['repost_author'] as Map<String, dynamic>)
            : null,
        repostedAt: _parseDateTime(json['reposted_at']),
        hashtags: List<String>.from(json['hashtags'] ?? []),
        mentions: List<String>.from(json['mentions'] ?? []),
        visibility: _parseVisibility(json['visibility']),
      );
    } catch (e, stackTrace) {
      logger.error('Error parsing PostModel from JSON', e, stackTrace);
      // Return a default post in case of parsing error
      return PostModel(
        id: json['id'] as String? ?? 'error',
        author: author,
        content: 'Error loading post',
        type: PostType.text,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Parse author from JSON with fallback for legacy format
  static UserModel _parseAuthor(Map<String, dynamic> json) {
    // Backend should always send author as nested object via ToResponse()
    if (json['author'] != null && json['author'] is Map) {
      return UserModel.fromJson(json['author'] as Map<String, dynamic>);
    }

    // REDNOTE: Remove this fallback once backend fully migrates to nested author objects
    // Temporary fallback for backward compatibility during backend migration
    final authorId = json['author_id'] ?? 'unknown';

    // Extract short username from UUID or use as-is if not UUID
    String displayName;
    if (authorId.toString().contains('-') && authorId.toString().length > 20) {
      displayName = 'User ${authorId.toString().substring(0, 8)}';
    } else {
      displayName = 'User $authorId';
    }

    return UserModel(
      id: authorId as String,
      email: 'user@anigmaa.com',
      name: displayName,
      createdAt: DateTime.now(),
      settings: const UserSettingsModel(),
      stats: const UserStatsModel(),
      privacy: const UserPrivacyModel(),
    );
  }

  /// Parse post type with fallback
  /// Handles both snake_case (backend) and camelCase (legacy) values
  static PostType _parsePostType(dynamic type) {
    if (type == null) return PostType.text;

    try {
      final typeStr = type.toString().toLowerCase();

      // Direct match with snake_case values (backend standard)
      for (final value in PostType.values) {
        if (value.toString().split('.').last == typeStr) {
          return value;
        }
      }

      // Legacy support for camelCase values
      final legacyMapping = {
        'textwithimages': PostType.text_with_images,
        'textwithevent': PostType.text_with_event,
      };

      if (legacyMapping.containsKey(typeStr)) {
        return legacyMapping[typeStr]!;
      }

      return PostType.text;
    } catch (e) {
      return PostType.text;
    }
  }

  /// Parse DateTime with null safety
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (e) {
      return null;
    }
  }

  /// Parse boolean value from various formats
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value > 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return null;
  }

  /// Parse visibility with fallback
  static PostVisibility _parseVisibility(dynamic visibility) {
    if (visibility == null) return PostVisibility.public;

    try {
      return PostVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == visibility.toString(),
      );
    } catch (e) {
      return PostVisibility.public;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': (author as UserModel).toJson(),
      'content': content,
      'type': type.toString().split('.').last, // Now outputs snake_case
      'imageUrls': imageUrls,
      'attachedEvent': attachedEvent != null
          ? (attachedEvent as EventModel).toJson()
          : null,
      'poll': poll != null ? (poll as PollModel).toJson() : null,
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'repostsCount': repostsCount,
      'sharesCount': sharesCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'isRepostedByCurrentUser': isRepostedByCurrentUser,
      'isBookmarked': isBookmarked,
      'originalPost':
          originalPost != null ? (originalPost as PostModel).toJson() : null,
      'repostAuthor':
          repostAuthor != null ? (repostAuthor as UserModel).toJson() : null,
      'repostedAt': repostedAt?.toIso8601String(),
      'hashtags': hashtags,
      'mentions': mentions,
      'visibility': visibility.toString().split('.').last,
    };
  }

  factory PostModel.fromEntity(Post post) {
    return PostModel(
      id: post.id,
      author: post.author,
      content: post.content,
      type: post.type,
      imageUrls: post.imageUrls,
      attachedEvent: post.attachedEvent,
      poll: post.poll,
      createdAt: post.createdAt,
      editedAt: post.editedAt,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      repostsCount: post.repostsCount,
      sharesCount: post.sharesCount,
      isLikedByCurrentUser: post.isLikedByCurrentUser,
      isRepostedByCurrentUser: post.isRepostedByCurrentUser,
      isBookmarked: post.isBookmarked,
      originalPost: post.originalPost,
      repostAuthor: post.repostAuthor,
      repostedAt: post.repostedAt,
      hashtags: post.hashtags,
      mentions: post.mentions,
      visibility: post.visibility,
    );
  }

  /// Parse attached event with proper error handling
  static Event? _parseAttachedEvent(Map<String, dynamic> json) {
    try {
      final eventData = json['attached_event'] ?? json['attachedEvent'];
      if (eventData == null) return null;

      // Parse as EventModel
      return EventModel.fromJson(eventData as Map<String, dynamic>);
    } catch (e, stackTrace) {
      AppLogger().error('[PostModel] Error parsing attached event', e, stackTrace);
      return null;
    }
  }
}

/// Data model for Poll entity
/// Handles poll-related data with proper validation
class PollModel extends Poll {
  const PollModel({
    required super.id,
    required super.question,
    required super.options,
    required super.endsAt,
    super.totalVotes = 0,
    super.hasVoted = false,
    super.votedOptionId,
  });

  /// Creates PollModel from JSON
  factory PollModel.fromJson(Map<String, dynamic> json) {
    try {
      return PollModel(
        id: json['id'] as String? ?? '',
        question: json['question'] as String? ?? '',
        options: (json['options'] as List<dynamic>?)
            ?.map((option) => PollOptionModel.fromJson(option as Map<String, dynamic>))
            .toList() ?? [],
        endsAt: DateTime.parse(json['ends_at'] as String? ?? DateTime.now().add(const Duration(days: 7)).toIso8601String()),
        totalVotes: json['total_votes'] as int? ?? 0,
        hasVoted: json['has_voted'] as bool? ?? false,
        votedOptionId: json['voted_option_id'] as String?,
      );
    } catch (e) {
      AppLogger().error('Error parsing PollModel from JSON', e);
      // Return default poll on error
      return PollModel(
        id: json['id'] as String? ?? '',
        question: 'Error loading poll',
        options: [],
        endsAt: DateTime.now().add(const Duration(days: 7)),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.map((option) => (option as PollOptionModel).toJson()).toList(),
      'endsAt': endsAt.toIso8601String(),
      'totalVotes': totalVotes,
      'hasVoted': hasVoted,
      'votedOptionId': votedOptionId,
    };
  }
}

/// Data model for PollOption entity
/// Represents individual options within a poll
class PollOptionModel extends PollOption {
  const PollOptionModel({
    required super.id,
    required super.text,
    super.votes = 0,
  });

  /// Creates PollOptionModel from JSON
  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'votes': votes,
    };
  }
}
