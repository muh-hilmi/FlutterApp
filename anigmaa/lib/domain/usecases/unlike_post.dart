import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class UnlikePost implements UseCase<Post, String> {
  final PostRepository repository;

  UnlikePost(this.repository);

  @override
  Future<Either<Failure, Post>> call(String postId) async {
    return await repository.unlikePost(postId);
  }
}
