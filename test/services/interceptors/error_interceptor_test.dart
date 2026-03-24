import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_assets_app/services/api_exception.dart';
import 'package:office_assets_app/services/interceptors/error_interceptor.dart';

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late ErrorInterceptor interceptor;
  late MockErrorInterceptorHandler handler;

  setUp(() {
    interceptor = ErrorInterceptor();
    handler = MockErrorInterceptorHandler();
  });

  DioException makeDioError(
    DioExceptionType type, {
    int? statusCode,
    dynamic data,
  }) {
    return DioException(
      type: type,
      requestOptions: RequestOptions(path: '/test'),
      response: statusCode != null
          ? Response(
              statusCode: statusCode,
              data: data,
              requestOptions: RequestOptions(path: '/test'),
            )
          : null,
    );
  }

  group('timeout errors throw NetworkException', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ]) {
      test('$type', () {
        expect(
          () => interceptor.onError(makeDioError(type), handler),
          throwsA(isA<NetworkException>()),
        );
      });
    }
  });

  group('badResponse', () {
    test('400 throws ValidationException with message from response', () {
      final err = makeDioError(
        DioExceptionType.badResponse,
        statusCode: 400,
        data: {'message': 'Email required'},
      );
      expect(
        () => interceptor.onError(err, handler),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          'Email required',
        )),
      );
    });

    test('401 throws UnauthorizedException', () {
      final err = makeDioError(
        DioExceptionType.badResponse,
        statusCode: 401,
        data: {'message': 'Token expired'},
      );
      expect(
        () => interceptor.onError(err, handler),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('403 throws ForbiddenException', () {
      final err = makeDioError(
        DioExceptionType.badResponse,
        statusCode: 403,
      );
      expect(
        () => interceptor.onError(err, handler),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('404 throws NotFoundException', () {
      final err = makeDioError(
        DioExceptionType.badResponse,
        statusCode: 404,
      );
      expect(
        () => interceptor.onError(err, handler),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('500 throws ServerException', () {
      final err = makeDioError(
        DioExceptionType.badResponse,
        statusCode: 500,
      );
      expect(
        () => interceptor.onError(err, handler),
        throwsA(isA<ServerException>()),
      );
    });

    test('503 throws ServerException with statusCode 503', () {
      final err = makeDioError(
        DioExceptionType.badResponse,
        statusCode: 503,
      );
      expect(
        () => interceptor.onError(err, handler),
        throwsA(isA<ServerException>().having(
          (e) => e.statusCode,
          'statusCode',
          503,
        )),
      );
    });
  });

  test('cancel calls handler.reject, no throw', () {
    final err = makeDioError(DioExceptionType.cancel);
    interceptor.onError(err, handler);
    verify(() => handler.reject(err)).called(1);
  });

  test('badCertificate throws NetworkException', () {
    expect(
      () => interceptor.onError(
        makeDioError(DioExceptionType.badCertificate),
        handler,
      ),
      throwsA(isA<NetworkException>()),
    );
  });

  test('unknown throws NetworkException', () {
    expect(
      () => interceptor.onError(
        makeDioError(DioExceptionType.unknown),
        handler,
      ),
      throwsA(isA<NetworkException>()),
    );
  });
}
