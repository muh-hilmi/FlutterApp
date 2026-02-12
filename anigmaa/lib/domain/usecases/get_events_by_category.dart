import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../entities/event_category.dart';
import '../repositories/event_repository.dart';

class GetEventsByCategory implements UseCase<PaginatedResponse<Event>, GetEventsByCategoryParams> {
  final EventRepository repository;

  GetEventsByCategory(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> call(GetEventsByCategoryParams params) async {
    return await repository.getEventsByCategory(
      params.category,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetEventsByCategoryParams {
  final EventCategory category;
  final int limit;
  final int offset;

  const GetEventsByCategoryParams({
    required this.category,
    this.limit = 20,
    this.offset = 0,
  });
}