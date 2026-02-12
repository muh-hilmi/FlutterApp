import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class LikePost implements UseCase<Post, String> {
  final PostRepository repository;

  LikePost(this.repository);

  @override
  Future<Either<Failure, Post>> call(String postId) async {
    return await repository.likePost(postId);
  }
}
