import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../core/usecases/usecase.dart';
import '../entities/comment.dart';
import '../repositories/post_repository.dart';

class GetCommentsParams {
  final String postId;
  final int limit;
  final int offset;

  GetCommentsParams({
    required this.postId,
    this.limit = 20,
    this.offset = 0,
  });
}

class GetComments implements UseCase<PaginatedResponse<Comment>, GetCommentsParams> {
  final PostRepository repository;

  GetComments(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Comment>>> call(GetCommentsParams params) async {
    return await repository.getComments(
      params.postId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
