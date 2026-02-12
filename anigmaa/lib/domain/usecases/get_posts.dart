import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../core/usecases/usecase.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class GetPosts implements UseCase<PaginatedResponse<Post>, GetPostsParams> {
  final PostRepository repository;

  GetPosts(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> call(GetPostsParams params) async {
    return await repository.getPosts(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetPostsParams {
  final int limit;
  final int offset;

  const GetPostsParams({
    this.limit = 20,
    this.offset = 0,
  });
}

class GetFeedPosts implements UseCase<PaginatedResponse<Post>, GetFeedPostsParams> {
  final PostRepository repository;

  GetFeedPosts(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> call(GetFeedPostsParams params) async {
    return await repository.getFeedPosts(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetFeedPostsParams {
  final int limit;
  final int offset;

  const GetFeedPostsParams({
    this.limit = 20,
    this.offset = 0,
  });
}
