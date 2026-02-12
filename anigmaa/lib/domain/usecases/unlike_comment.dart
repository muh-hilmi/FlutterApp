import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/comment.dart';
import '../repositories/post_repository.dart';

class UnlikeCommentParams {
  final String postId;
  final String commentId;

  UnlikeCommentParams({
    required this.postId,
    required this.commentId,
  });
}

class UnlikeComment implements UseCase<Comment, UnlikeCommentParams> {
  final PostRepository repository;

  UnlikeComment(this.repository);

  @override
  Future<Either<Failure, Comment>> call(UnlikeCommentParams params) async {
    return await repository.unlikeComment(params.postId, params.commentId);
  }
}
