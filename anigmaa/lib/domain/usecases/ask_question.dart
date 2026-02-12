import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/qna.dart';
import '../repositories/qna_repository.dart';

class AskQuestion implements UseCase<QnA, AskQuestionParams> {
  final QnARepository repository;

  AskQuestion(this.repository);

  @override
  Future<Either<Failure, QnA>> call(AskQuestionParams params) async {
    return await repository.askQuestion(params.eventId, params.question);
  }
}

class AskQuestionParams {
  final String eventId;
  final String question;

  AskQuestionParams({
    required this.eventId,
    required this.question,
  });
}
