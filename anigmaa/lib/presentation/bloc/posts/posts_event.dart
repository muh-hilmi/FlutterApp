import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/comment.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPosts extends PostsEvent {}

class RefreshPosts extends PostsEvent {}

class LoadMorePosts extends PostsEvent {}

class CreatePostRequested extends PostsEvent {
  final Post post;

  const CreatePostRequested(this.post);

  @override
  List<Object?> get props => [post];
}

class LikePostToggled extends PostsEvent {
  final String postId;
  final bool isCurrentlyLiked;

  const LikePostToggled(this.postId, this.isCurrentlyLiked);

  @override
  List<Object?> get props => [postId, isCurrentlyLiked];
}

class RepostRequested extends PostsEvent {
  final String postId;
  final String? quoteContent;

  const RepostRequested(this.postId, {this.quoteContent});

  @override
  List<Object?> get props => [postId, quoteContent];
}

class LoadComments extends PostsEvent {
  final String postId;

  const LoadComments(this.postId);

  @override
  List<Object?> get props => [postId];
}

class CreateCommentRequested extends PostsEvent {
  final Comment comment;

  const CreateCommentRequested(this.comment);

  @override
  List<Object?> get props => [comment];
}

class LikeCommentToggled extends PostsEvent {
  final String postId;
  final String commentId;
  final bool isCurrentlyLiked;

  const LikeCommentToggled(this.postId, this.commentId, this.isCurrentlyLiked);

  @override
  List<Object?> get props => [postId, commentId, isCurrentlyLiked];
}

class DeleteCommentRequested extends PostsEvent {
  final String postId;
  final String commentId;

  const DeleteCommentRequested(this.postId, this.commentId);

  @override
  List<Object?> get props => [postId, commentId];
}

class SavePostToggled extends PostsEvent {
  final String postId;
  final bool isCurrentlySaved;

  const SavePostToggled(this.postId, this.isCurrentlySaved);

  @override
  List<Object?> get props => [postId, isCurrentlySaved];
}

class LoadSavedPosts extends PostsEvent {}

class ArchivePostRequested extends PostsEvent {
  final String postId;

  const ArchivePostRequested(this.postId);

  @override
  List<Object?> get props => [postId];
}

class UnarchivePostRequested extends PostsEvent {
  final String postId;

  const UnarchivePostRequested(this.postId);

  @override
  List<Object?> get props => [postId];
}

class LoadArchivedPosts extends PostsEvent {}
