import 'package:dio/dio.dart';
import '../api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw const NetworkException('Connection timed out. Check your network.');

      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode ?? 0;
        final data = response?.data;
        final message = data is Map ? (data['message'] as String?) : null;

        switch (statusCode) {
          case 400:
            throw ValidationException(
              message ?? 'Invalid request.',
              400,
              data is Map ? Map<String, dynamic>.from(data) : null,
            );
          case 401:
            throw UnauthorizedException(message ?? 'Session expired. Please log in again.');
          case 403:
            throw ForbiddenException(message ?? 'You do not have permission for this action.');
          case 404:
            throw NotFoundException(message ?? 'Resource not found.');
          case >= 500:
            throw ServerException(message ?? 'Server error. Please try again later.', statusCode);
          default:
            throw ServerException(message ?? 'Unexpected error.', statusCode);
        }

      case DioExceptionType.cancel:
        // Request was cancelled — don't throw, just reject
        handler.reject(err);
        return;

      case DioExceptionType.badCertificate:
        throw const NetworkException('Security certificate error.');

      case DioExceptionType.unknown:
        throw NetworkException(err.message ?? 'An unexpected error occurred.');
    }
  }
}
