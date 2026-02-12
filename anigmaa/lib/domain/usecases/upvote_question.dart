import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/qna.dart';
import '../repositories/qna_repository.dart';

class UpvoteQuestion implements UseCase<QnA, String> {
  final QnARepository repository;

  UpvoteQuestion(this.repository);

  @override
  Future<Either<Failure, QnA>> call(String questionId) async {
    return await repository.upvoteQuestion(questionId);
  }
}

class RemoveUpvote implements UseCase<QnA, String> {
  final QnARepository repository;

  RemoveUpvote(this.repository);

  @override
  Future<Either<Failure, QnA>> call(String questionId) async {
    return await repository.removeUpvote(questionId);
  }
}
