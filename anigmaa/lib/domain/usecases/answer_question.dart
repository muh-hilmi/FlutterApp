import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/qna.dart';

import '../repositories/qna_repository.dart';

/// Use case for answering a question (for event organizers/hosts)
class AnswerQuestion implements UseCase<QnA, AnswerQuestionParams> {
  final QnARepository repository;

  AnswerQuestion(this.repository);

  @override
  Future<Either<Failure, QnA>> call(AnswerQuestionParams params) async {
    return await repository.answerQuestion(params.questionId, params.answer);
  }
}

/// Parameters for answering a question
class AnswerQuestionParams {
  final String questionId;
  final String answer;

  AnswerQuestionParams({required this.questionId, required this.answer});
}
