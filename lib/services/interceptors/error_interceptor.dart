import 'package:dio/dio.dart';
import '../api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    ApiException apiException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        apiException = const NetworkException('Connection timed out. Check your network.');

      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode ?? 0;
        final data = response?.data;
        final message = data is Map ? (data['message'] as String?) : null;

        switch (statusCode) {
          case 400:
            apiException = ValidationException(
              message ?? 'Invalid request.',
              400,
              data is Map ? Map<String, dynamic>.from(data) : null,
            );
          case 401:
            apiException = UnauthorizedException(message ?? 'Session expired. Please log in again.');
          case 403:
            apiException = ForbiddenException(message ?? 'You do not have permission for this action.');
          case 404:
            apiException = NotFoundException(message ?? 'Resource not found.');
          case >= 500:
            apiException = ServerException(message ?? 'Server error. Please try again later.', statusCode);
          default:
            apiException = ServerException(message ?? 'Unexpected error.', statusCode);
        }

      case DioExceptionType.cancel:
        handler.reject(err);
        return;

      case DioExceptionType.badCertificate:
        apiException = const NetworkException('Security certificate error.');

      case DioExceptionType.unknown:
        // Check if already wrapped from a previous interceptor pass
        if (err.error is ApiException) {
          apiException = err.error as ApiException;
        } else {
          apiException = NetworkException(err.message ?? 'An unexpected error occurred.');
        }
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ),
    );
  }
}
