import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEvents implements UseCase<PaginatedResponse<Event>, GetEventsParams> {
  final EventRepository repository;

  GetEvents(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> call(GetEventsParams params) async {
    return await repository.getEvents(
      limit: params.limit,
      offset: params.offset,
      mode: params.mode,
    );
  }
}

class GetEventsParams {
  final int limit;
  final int offset;
  final String? mode; // 'trending', 'for_you', 'chill'

  const GetEventsParams({
    this.limit = 20,
    this.offset = 0,
    this.mode,
  });
}