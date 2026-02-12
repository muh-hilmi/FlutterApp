import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class RepostPost implements UseCase<Post, RepostPostParams> {
  final PostRepository repository;

  RepostPost(this.repository);

  @override
  Future<Either<Failure, Post>> call(RepostPostParams params) async {
    return await repository.repostPost(
      params.postId,
      quoteContent: params.quoteContent,
    );
  }
}

class RepostPostParams {
  final String postId;
  final String? quoteContent;

  const RepostPostParams({
    required this.postId,
    this.quoteContent,
  });
}
