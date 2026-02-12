import 'package:dio/dio.dart';
import '../../utils/app_logger.dart';

/// Logging interceptor for HTTP requests
/// Shows detailed logs in development for debugging
class LoggingInterceptor extends Interceptor {
  final _startTimes = <RequestOptions, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _startTimes[options] = DateTime.now();
    NetworkLogger.logRequest(
      options.method,
      options.path,
      queryParams: options.queryParameters,
      data: options.data,
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final duration = _startTimes[response.requestOptions] != null
        ? DateTime.now().difference(_startTimes[response.requestOptions]!)
        : null;
    _startTimes.remove(response.requestOptions);

    NetworkLogger.logResponse(
      response.statusCode,
      response.requestOptions.path,
      duration: duration,
      data: response.data,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _startTimes.remove(err.requestOptions);

    final errorMessage = err.response?.data is Map
        ? err.response?.data['message']
        : err.message;

    NetworkLogger.logError(
      err.response?.statusCode,
      err.requestOptions.path,
      errorMessage,
      errorData: err.response?.data,
    );
    handler.next(err);
  }
}
