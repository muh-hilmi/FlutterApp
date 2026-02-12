import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/qna_repository.dart';

/// Use case for deleting a question (for event organizers/hosts)
class DeleteQuestion implements UseCase<void, String> {
  final QnARepository repository;

  DeleteQuestion(this.repository);

  @override
  Future<Either<Failure, void>> call(String questionId) async {
    return await repository.deleteQuestion(questionId);
  }
}
