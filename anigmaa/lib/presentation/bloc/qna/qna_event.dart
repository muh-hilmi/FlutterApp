import 'package:equatable/equatable.dart';

abstract class QnAEvent extends Equatable {
  const QnAEvent();

  @override
  List<Object?> get props => [];
}

class LoadEventQnA extends QnAEvent {
  final String eventId;

  const LoadEventQnA(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class RefreshEventQnA extends QnAEvent {
  final String eventId;

  const RefreshEventQnA(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class AskQuestionRequested extends QnAEvent {
  final String eventId;
  final String question;

  const AskQuestionRequested(this.eventId, this.question);

  @override
  List<Object?> get props => [eventId, question];
}

class UpvoteQuestionToggled extends QnAEvent {
  final String questionId;
  final bool isCurrentlyUpvoted;

  const UpvoteQuestionToggled(this.questionId, this.isCurrentlyUpvoted);

  @override
  List<Object?> get props => [questionId, isCurrentlyUpvoted];
}

// Host actions for managing Q&A
class AnswerQuestionRequested extends QnAEvent {
  final String questionId;
  final String answer;

  const AnswerQuestionRequested({
    required this.questionId,
    required this.answer,
  });

  @override
  List<Object?> get props => [questionId, answer];
}

class DeleteQuestionRequested extends QnAEvent {
  final String questionId;

  const DeleteQuestionRequested(this.questionId);

  @override
  List<Object?> get props => [questionId];
}
