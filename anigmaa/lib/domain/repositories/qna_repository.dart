import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/qna.dart';

abstract class QnARepository {
  /// Get all Q&A for an event
  Future<Either<Failure, List<QnA>>> getEventQnA(String eventId);

  /// Ask a question for an event
  Future<Either<Failure, QnA>> askQuestion(String eventId, String question);

  /// Answer a question (for event organizers)
  Future<Either<Failure, QnA>> answerQuestion(String questionId, String answer);

  /// Upvote a question
  Future<Either<Failure, QnA>> upvoteQuestion(String questionId);

  /// Remove upvote from a question
  Future<Either<Failure, QnA>> removeUpvote(String questionId);

  /// Delete a question
  Future<Either<Failure, void>> deleteQuestion(String questionId);
}
