import 'dart:async';
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';
import '../network/error_classifier.dart';

/// Mixin for BLoCs that need network resilience
///
/// Provides automatic retry logic with exponential backoff for failed requests.
/// Distinguishes between retryable and non-retryable errors.
///
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with NetworkResilienceBloc {
///   Future<void> _onFetchData(FetchData event, Emitter<MyState> emit) async {
///     emit(MyLoading());
///
///     final result = await executeWithRetry(
///       () => myRepository.getData(),
///       maxRetries: 3,
///     );
///
///     result.fold(
///       (failure) => emit(MyError(failure.message)),
///       (data) => emit(MyLoaded(data)),
///     );
///   }
/// }
/// ```
mixin NetworkResilienceBloc {
  /// Execute a request with automatic retry on transient failures
  ///
  /// `request`: The function to execute (should return `Either<Failure, T>`)
  /// `maxRetries`: Maximum number of retry attempts (default: 3)
  /// `initialBackoff`: Initial backoff duration (default: 2 seconds)
  /// `maxBackoff`: Maximum backoff duration (default: 30 seconds)
  ///
  /// Returns `Either<Failure, T>` with the result or failure
  Future<Either<Failure, T>> executeWithRetry<T>(
    Future<Either<Failure, T>> Function() request, {
    int maxRetries = 3,
    Duration initialBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(seconds: 30),
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;

      try {
        final result = await request();

        // Check if result is a failure that might be retryable
        return result.fold(
          (failure) {
            final networkError = _classifyFailure(failure);

            if (networkError.isRetryable && attempt < maxRetries) {
              // Retry this attempt
              throw _RetryableException(
                failure: failure,
                attempt: attempt,
                networkError: networkError,
              );
            }

            // Non-retryable or max retries reached
            return Left(failure);
          },
          (success) => Right(success),
        );
      } catch (e) {
        if (e is! _RetryableException) {
          // Not a retryable exception, return as failure
          return Left(_convertToFailure(e));
        }

        // Calculate backoff duration
        final backoff = _calculateBackoff(
          e.attempt,
          initialBackoff,
          maxBackoff,
        );

        // Retry attempt ${e.attempt}/$maxRetries after ${backoff.inSeconds}s

        // Wait before retrying
        await Future.delayed(backoff);

        // Loop will continue and retry
      }
    }
  }

  /// Execute a raw Future with retry (for non-Either returning functions)
  ///
  /// This is useful when calling API methods that throw exceptions
  /// instead of returning Either.
  Future<T> executeWithRetryRaw<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration initialBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(seconds: 30),
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;

      try {
        return await request();
      } catch (e) {
        final networkError = ErrorClassifier.classify(e);

        if (!networkError.isRetryable || attempt >= maxRetries) {
          rethrow;
        }

        final backoff = _calculateBackoff(attempt, initialBackoff, maxBackoff);

        // Retry attempt $attempt/$maxRetries after ${backoff.inSeconds}s

        await Future.delayed(backoff);
      }
    }
  }

  /// Classify a Failure into a NetworkError
  NetworkError _classifyFailure(Failure failure) {
    // Create a synthetic NetworkError from the Failure
    // Auth errors are NEVER retryable at BLoC level - let AuthInterceptor handle
    if (failure is AuthenticationFailure || failure is UnauthorizedFailure) {
      return const NetworkError(
        type: ErrorType.auth,
        action: RecoveryAction.showError,
        message: 'Authentication failed',
        isRetryable: false, // NEVER retry auth errors
      );
    }

    final type = switch (failure.runtimeType.toString()) {
      'NetworkFailure' => ErrorType.network,
      'TimeoutFailure' => ErrorType.timeout,
      'ServerFailure' => ErrorType.server,
      _ => ErrorType.unknown,
    };

    return NetworkError(
      type: type,
      action: RecoveryAction.showError,
      message: failure.message,
      isRetryable: type == ErrorType.network ||
                   type == ErrorType.timeout ||
                   type == ErrorType.server,
    );
  }

  /// Convert an exception to a Failure
  Failure _convertToFailure(dynamic error) {
    final networkError = ErrorClassifier.classify(error);
    return networkError.toFailure();
  }

  /// Calculate exponential backoff duration
  Duration _calculateBackoff(
    int attempt,
    Duration initialBackoff,
    Duration maxBackoff,
  ) {
    // Exponential backoff: 2^attempt seconds
    final exponential = (1 << attempt).toDouble();
    final milliseconds = (initialBackoff.inMilliseconds * exponential)
        .clamp(initialBackoff.inMilliseconds, maxBackoff.inMilliseconds);

    // Add jitter (±20% randomness to prevent thundering herd)
    final jitter = (milliseconds * 0.2 * (DateTime.now().millisecond % 100 - 50) / 100).toInt();

    return Duration(milliseconds: (milliseconds + jitter).toInt());
  }
}

/// Internal exception for retryable failures
class _RetryableException implements Exception {
  final Failure failure;
  final int attempt;
  final NetworkError networkError;

  _RetryableException({
    required this.failure,
    required this.attempt,
    required this.networkError,
  });
}
