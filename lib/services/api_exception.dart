/// Base exception for all API-related errors.
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// Network unreachable, DNS failure, timeout.
class NetworkException extends ApiException {
  const NetworkException([String message = 'No internet connection'])
      : super(message, 0);
}

/// 401 — token expired or invalid.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Session expired. Please log in again.'])
      : super(message, 401);
}

/// 403 — insufficient permissions.
class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'You do not have permission for this action.'])
      : super(message, 403);
}

/// 404 — resource not found.
class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found.'])
      : super(message, 404);
}

/// 422 / 400 — validation or bad request.
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  const ValidationException(
    super.message, [
    super.statusCode,
    this.errors,
  ]);
}

/// 5xx — server-side failure.
class ServerException extends ApiException {
  const ServerException([String message = 'Server error. Please try again later.', int? statusCode])
      : super(message, statusCode ?? 500);
}
