import 'package:equatable/equatable.dart';
import 'user.dart';
import 'event.dart';

/// Enumeration of supported post types
/// Defines the different formats a post can take
/// NOTE: Values use snake_case to match backend database enum
// ignore: constant_identifier_names
enum PostType {
  /// Plain text post
  text,

  /// Text post with attached images
  // ignore: constant_identifier_names
  text_with_images,

  /// Text post with attached event
  // ignore: constant_identifier_names
  text_with_event,

  /// Interactive poll post
  poll,

  /// Reposted content from another user
  repost,
}

/// Enumeration of post visibility levels
/// Controls who can see the post content
enum PostVisibility {
  /// Visible to everyone
  public,

  /// Visible only to followers
  followers,

  /// Visible only to the author
  private,
}

/// Core domain entity for social media posts
/// Represents any content created by users in the system
class Post extends Equatable {
  final String id;
  final User author;
  final String content;
  final PostType type;
  final List<String> imageUrls;
  final Event? attachedEvent;
  final Poll? poll;
  final DateTime createdAt;
  final DateTime? editedAt;

  // Engagement metrics
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final int sharesCount;

  // User interactions
  final bool isLikedByCurrentUser;
  final bool isRepostedByCurrentUser;
  final bool isBookmarked;

  // Repost data (if this post is a repost)
  final Post? originalPost;
  final User? repostAuthor;
  final DateTime? repostedAt;

  // Hashtags and mentions
  final List<String> hashtags;
  final List<String> mentions; // user IDs

  // Visibility
  final PostVisibility visibility;

  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.type,
    this.imageUrls = const [],
    this.attachedEvent,
    this.poll,
    required this.createdAt,
    this.editedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.sharesCount = 0,
    this.isLikedByCurrentUser = false,
    this.isRepostedByCurrentUser = false,
    this.isBookmarked = false,
    this.originalPost,
    this.repostAuthor,
    this.repostedAt,
    this.hashtags = const [],
    this.mentions = const [],
    this.visibility = PostVisibility.public,
  });

  Post copyWith({
    String? id,
    User? author,
    String? content,
    PostType? type,
    List<String>? imageUrls,
    Event? attachedEvent,
    Poll? poll,
    DateTime? createdAt,
    DateTime? editedAt,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    int? sharesCount,
    bool? isLikedByCurrentUser,
    bool? isRepostedByCurrentUser,
    bool? isBookmarked,
    Post? originalPost,
    User? repostAuthor,
    DateTime? repostedAt,
    List<String>? hashtags,
    List<String>? mentions,
    PostVisibility? visibility,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrls: imageUrls ?? this.imageUrls,
      attachedEvent: attachedEvent ?? this.attachedEvent,
      poll: poll ?? this.poll,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isRepostedByCurrentUser: isRepostedByCurrentUser ?? this.isRepostedByCurrentUser,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      originalPost: originalPost ?? this.originalPost,
      repostAuthor: repostAuthor ?? this.repostAuthor,
      repostedAt: repostedAt ?? this.repostedAt,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      visibility: visibility ?? this.visibility,
    );
  }

  // Helper methods for UI state management

  /// Checks if the post has been edited after creation
  bool get isEdited => editedAt != null && !editedAt!.isAtSameMomentAs(createdAt);

  /// Checks if the post is a repost of another post
  bool get isRepost => type == PostType.repost || originalPost != null;

  /// Checks if the post has any media content (images or poll)
  bool get hasMedia => imageUrls.isNotEmpty || poll != null;

  /// Checks if the post is interactive (has poll or event)
  bool get isInteractive => poll != null || attachedEvent != null;

  /// Gets the display content for reposts
  /// Returns the quote content if available, otherwise returns original post's content
  String get displayContent {
    if (isRepost && content.trim().isEmpty && originalPost != null) {
      return originalPost!.content;
    }
    return content;
  }

  /// Formats the creation time for display
  /// Returns relative time (e.g., "2 hours ago") or formatted date
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Return formatted date for older posts
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        author,
        content,
        type,
        imageUrls,
        attachedEvent,
        poll,
        createdAt,
        editedAt,
        likesCount,
        commentsCount,
        repostsCount,
        sharesCount,
        isLikedByCurrentUser,
        isRepostedByCurrentUser,
        isBookmarked,
        originalPost,
        repostAuthor,
        repostedAt,
        hashtags,
        mentions,
        visibility,
      ];
}

/// Represents an interactive poll within a post
/// Contains a question, multiple options, and voting data
class Poll extends Equatable {
  final String id;
  final String question;
  final List<PollOption> options;
  final DateTime endsAt;
  final int totalVotes;
  final bool hasVoted;
  final String? votedOptionId;

  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.endsAt,
    this.totalVotes = 0,
    this.hasVoted = false,
    this.votedOptionId,
  });

  /// Checks if the poll has ended
  /// Returns true if current time is after the end time
  bool get isEnded => DateTime.now().isAfter(endsAt);

  /// Checks if the poll is still active and accepting votes
  bool get isActive => !isEnded;

  /// Gets the winning option (most votes)
  /// Returns null if there are no votes or a tie
  PollOption? getLeadingOption() {
    if (totalVotes == 0 || options.isEmpty) return null;

    final sortedOptions = List<PollOption>.from(options)
      ..sort((a, b) => b.votes.compareTo(a.votes));

    final leadingOption = sortedOptions.first;
    final secondOption = sortedOptions.length > 1 ? sortedOptions[1] : null;

    // Return null if there's a tie
    if (secondOption != null && leadingOption.votes == secondOption.votes) {
      return null;
    }

    return leadingOption;
  }

  @override
  List<Object?> get props => [
        id,
        question,
        options,
        endsAt,
        totalVotes,
        hasVoted,
        votedOptionId,
      ];
}

/// Represents an individual option within a poll
/// Contains the option text and vote count
class PollOption extends Equatable {
  final String id;
  final String text;
  final int votes;

  const PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });

  /// Calculates the percentage of votes for this option
  /// Returns 0 if totalVotes is 0 to avoid division by zero
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (votes / totalVotes) * 100;
  }

  @override
  List<Object?> get props => [id, text, votes];
}
