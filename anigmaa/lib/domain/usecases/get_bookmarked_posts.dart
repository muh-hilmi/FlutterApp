import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class GetBookmarkedPostsParams {
  final int limit;
  final int offset;

  const GetBookmarkedPostsParams({
    this.limit = 20,
    this.offset = 0,
  });
}

class GetBookmarkedPosts implements UseCase<List<Post>, GetBookmarkedPostsParams> {
  final PostRepository repository;

  GetBookmarkedPosts(this.repository);

  @override
  Future<Either<Failure, List<Post>>> call(GetBookmarkedPostsParams params) async {
    return await repository.getBookmarkedPosts(
      limit: params.limit,
      offset: params.offset,
    );
  }
}
