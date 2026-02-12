import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetNearbyEvents
    implements UseCase<PaginatedResponse<Event>, GetNearbyEventsParams> {
  final EventRepository repository;

  GetNearbyEvents(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> call(
    GetNearbyEventsParams params,
  ) async {
    return await repository.getNearbyEvents(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusKm: params.radiusKm,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetNearbyEventsParams extends Equatable {
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final int limit;
  final int offset;

  const GetNearbyEventsParams({
    this.latitude,
    this.longitude,
    this.radiusKm = 10,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, limit, offset];
}
