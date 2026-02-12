import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base class for all use cases in the application
/// Follows Clean Architecture principles with generic type parameters
///
/// [T] - The return type of the use case
/// [Params] - The parameter type required by the use case
abstract class UseCase<T, Params> {
  /// Executes the use case with the given parameters
  /// Returns Either<Failure, T> for error handling
  Future<Either<Failure, T>> call(Params params);
}

/// Parameter-less use case marker class
/// Used when a use case doesn't require any parameters
class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoParams;

  @override
  int get hashCode => 0;
}