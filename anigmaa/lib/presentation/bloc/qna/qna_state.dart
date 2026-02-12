import 'package:equatable/equatable.dart';
import '../../../domain/entities/qna.dart';

abstract class QnAState extends Equatable {
  const QnAState();

  @override
  List<Object?> get props => [];
}

class QnAInitial extends QnAState {}

class QnALoading extends QnAState {}

class QnALoaded extends QnAState {
  final List<QnA> questions;
  final String eventId;

  const QnALoaded({
    required this.questions,
    required this.eventId,
  });

  QnALoaded copyWith({
    List<QnA>? questions,
    String? eventId,
  }) {
    return QnALoaded(
      questions: questions ?? this.questions,
      eventId: eventId ?? this.eventId,
    );
  }

  @override
  List<Object?> get props => [questions, eventId];
}

class QnAError extends QnAState {
  final String message;

  const QnAError(this.message);

  @override
  List<Object?> get props => [message];
}
