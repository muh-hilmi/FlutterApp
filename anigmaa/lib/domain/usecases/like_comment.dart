import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/comment.dart';
import '../repositories/post_repository.dart';

class LikeCommentParams {
  final String postId;
  final String commentId;

  LikeCommentParams({
    required this.postId,
    required this.commentId,
  });
}

class LikeComment implements UseCase<Comment, LikeCommentParams> {
  final PostRepository repository;

  LikeComment(this.repository);

  @override
  Future<Either<Failure, Comment>> call(LikeCommentParams params) async {
    return await repository.likeComment(params.postId, params.commentId);
  }
}
