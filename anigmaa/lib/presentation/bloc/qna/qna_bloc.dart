import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_event_qna.dart';
import '../../../domain/usecases/ask_question.dart';
import '../../../domain/usecases/upvote_question.dart';
import '../../../domain/usecases/answer_question.dart';
import '../../../domain/usecases/delete_question.dart';
import '../../../core/utils/logger.dart';
import 'qna_event.dart';
import 'qna_state.dart';

class QnABloc extends Bloc<QnAEvent, QnAState> {
  final GetEventQnA getEventQnA;
  final AskQuestion askQuestion;
  final UpvoteQuestion upvoteQuestion;
  final RemoveUpvote removeUpvote;
  final AnswerQuestion answerQuestion;
  final DeleteQuestion deleteQuestion;

  QnABloc({
    required this.getEventQnA,
    required this.askQuestion,
    required this.upvoteQuestion,
    required this.removeUpvote,
    required this.answerQuestion,
    required this.deleteQuestion,
  }) : super(QnAInitial()) {
    on<LoadEventQnA>(_onLoadEventQnA);
    on<RefreshEventQnA>(_onRefreshEventQnA);
    on<AskQuestionRequested>(_onAskQuestion);
    on<UpvoteQuestionToggled>(_onUpvoteToggled);
    on<AnswerQuestionRequested>(_onAnswerQuestion);
    on<DeleteQuestionRequested>(_onDeleteQuestion);
  }

  Future<void> _onLoadEventQnA(
    LoadEventQnA event,
    Emitter<QnAState> emit,
  ) async {
    emit(QnALoading());

    try {
      final result = await getEventQnA(
        GetEventQnAParams(eventId: event.eventId),
      );

      result.fold(
        (failure) {
          logger.e('[QnABloc] Failed to load Q&A: ${failure.toString()}');
          emit(QnAError('Failed to load Q&A: ${failure.toString()}'));
        },
        (questions) {
          logger.i('[QnABloc] Successfully loaded ${questions.length} questions');
          emit(QnALoaded(questions: questions, eventId: event.eventId));
        },
      );
    } catch (e, stackTrace) {
      logger.e('[QnABloc] Exception loading Q&A: $e');
      logger.d('[QnABloc] Stack trace: $stackTrace');
      emit(QnAError('Exception loading Q&A: $e'));
    }
  }

  Future<void> _onRefreshEventQnA(
    RefreshEventQnA event,
    Emitter<QnAState> emit,
  ) async {
    try {
      final result = await getEventQnA(
        GetEventQnAParams(eventId: event.eventId),
      );

      result.fold(
        (failure) {
          logger.e('[QnABloc] Failed to refresh Q&A: ${failure.toString()}');
          // Keep current state, just log the error
        },
        (questions) {
          logger.i(
            '[QnABloc] Successfully refreshed ${questions.length} questions',
          );
          emit(QnALoaded(questions: questions, eventId: event.eventId));
        },
      );
    } catch (e) {
      logger.e('[QnABloc] Exception refreshing Q&A: $e');
    }
  }

  Future<void> _onAskQuestion(
    AskQuestionRequested event,
    Emitter<QnAState> emit,
  ) async {
    logger.d('[QnABloc] Asking question for event ${event.eventId}');

    try {
      final result = await askQuestion(
        AskQuestionParams(eventId: event.eventId, question: event.question),
      );

      await result.fold(
        (failure) async {
          logger.e('[QnABloc] Failed to ask question: ${failure.toString()}');
          emit(QnAError('Failed to ask question: ${failure.toString()}'));
        },
        (newQuestion) async {
          logger.i('[QnABloc] Question asked successfully: ${newQuestion.id}');
          logger.d('[QnABloc] Now refreshing Q&A list...');

          // Immediately reload Q&A list to show new question
          final refreshResult = await getEventQnA(
            GetEventQnAParams(eventId: event.eventId),
          );

          refreshResult.fold(
            (failure) {
              logger.e('[QnABloc] Failed to refresh after ask: $failure');
              emit(QnAError('Failed to refresh Q&A list'));
            },
            (questions) {
              logger.i(
                '[QnABloc] Successfully refreshed with ${questions.length} questions',
              );
              emit(QnALoaded(questions: questions, eventId: event.eventId));
            },
          );
        },
      );
    } catch (e, stackTrace) {
      logger.e('[QnABloc] Exception asking question: $e');
      logger.d('[QnABloc] Stack trace: $stackTrace');
      emit(QnAError('Exception: $e'));
    }
  }

  Future<void> _onUpvoteToggled(
    UpvoteQuestionToggled event,
    Emitter<QnAState> emit,
  ) async {
    if (state is! QnALoaded) return;

    final currentState = state as QnALoaded;

    // Optimistic update - update UI immediately
    final updatedQuestions = currentState.questions.map((question) {
      if (question.id == event.questionId) {
        return question.copyWith(
          isUpvotedByCurrentUser: !event.isCurrentlyUpvoted,
          upvotes: event.isCurrentlyUpvoted
              ? (question.upvotes > 0 ? question.upvotes - 1 : 0)
              : question.upvotes + 1,
        );
      }
      return question;
    }).toList();

    emit(currentState.copyWith(questions: updatedQuestions));

    // Call API in background
    try {
      final result = event.isCurrentlyUpvoted
          ? await removeUpvote(event.questionId)
          : await upvoteQuestion(event.questionId);

      result.fold(
        (failure) {
          logger.e('[QnABloc] Failed to update upvote, reverting: $failure');
          // Revert the optimistic update
          final revertedQuestions = updatedQuestions.map((question) {
            if (question.id == event.questionId) {
              return question.copyWith(
                isUpvotedByCurrentUser: event.isCurrentlyUpvoted,
                upvotes: event.isCurrentlyUpvoted
                    ? question.upvotes + 1
                    : (question.upvotes > 0 ? question.upvotes - 1 : 0),
              );
            }
            return question;
          }).toList();
          emit(currentState.copyWith(questions: revertedQuestions));
        },
        (updatedQuestion) {
          logger.i('[QnABloc] Upvote update successful');
          // Keep the optimistic update
        },
      );
    } catch (e) {
      logger.e('[QnABloc] Exception updating upvote: $e');
    }
  }

  Future<void> _onAnswerQuestion(
    AnswerQuestionRequested event,
    Emitter<QnAState> emit,
  ) async {
    if (state is! QnALoaded) return;

    final currentState = state as QnALoaded;
    final currentQuestions = currentState.questions;

    // Optimistic update - show answer immediately
    final updatedQuestions = currentQuestions.map((q) {
      if (q.id == event.questionId) {
        return q.copyWith(
          answer: event.answer,
          answeredAt: DateTime.now(),
        );
      }
      return q;
    }).toList();

    emit(currentState.copyWith(questions: updatedQuestions));

    // Call API in background
    try {
      final result = await answerQuestion(
        AnswerQuestionParams(
          questionId: event.questionId,
          answer: event.answer,
        ),
      );

      result.fold(
        (failure) {
          logger.e('[QnABloc] Failed to answer question, reverting: $failure');
          // Revert the optimistic update
          emit(currentState.copyWith(questions: currentQuestions));
        },
        (updatedQuestion) {
          logger.i('[QnABloc] Question answered successfully: ${updatedQuestion.id}');
          // Keep the optimistic update, or use the server response if needed
        },
      );
    } catch (e) {
      logger.e('[QnABloc] Exception answering question: $e');
      // Revert on exception
      emit(currentState.copyWith(questions: currentQuestions));
    }
  }

  Future<void> _onDeleteQuestion(
    DeleteQuestionRequested event,
    Emitter<QnAState> emit,
  ) async {
    if (state is! QnALoaded) return;

    final currentState = state as QnALoaded;
    final currentQuestions = currentState.questions;

    // Optimistic update - remove question immediately
    final updatedQuestions = currentQuestions.where((q) => q.id != event.questionId).toList();

    emit(currentState.copyWith(questions: updatedQuestions));

    // Call API in background
    try {
      final result = await deleteQuestion(event.questionId);

      result.fold(
        (failure) {
          logger.e('[QnABloc] Failed to delete question, reverting: $failure');
          // Revert the optimistic update
          emit(currentState.copyWith(questions: currentQuestions));
        },
        (_) {
          logger.i('[QnABloc] Question deleted successfully: ${event.questionId}');
          // Keep the optimistic update
        },
      );
    } catch (e) {
      logger.e('[QnABloc] Exception deleting question: $e');
      // Revert on exception
      emit(currentState.copyWith(questions: currentQuestions));
    }
  }
}
