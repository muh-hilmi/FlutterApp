import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/comment.dart';
import '../repositories/post_repository.dart';

class CreateComment implements UseCase<Comment, CreateCommentParams> {
  final PostRepository repository;

  CreateComment(this.repository);

  @override
  Future<Either<Failure, Comment>> call(CreateCommentParams params) async {
    return await repository.createComment(params.comment);
  }
}

class CreateCommentParams {
  final Comment comment;

  const CreateCommentParams({required this.comment});
}
