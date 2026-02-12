import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/qna.dart';
import '../repositories/qna_repository.dart';

class GetEventQnA implements UseCase<List<QnA>, GetEventQnAParams> {
  final QnARepository repository;

  GetEventQnA(this.repository);

  @override
  Future<Either<Failure, List<QnA>>> call(GetEventQnAParams params) async {
    return await repository.getEventQnA(params.eventId);
  }
}

class GetEventQnAParams {
  final String eventId;

  GetEventQnAParams({required this.eventId});
}
