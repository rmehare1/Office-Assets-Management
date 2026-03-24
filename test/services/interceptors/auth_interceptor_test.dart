import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_assets_app/services/interceptors/auth_interceptor.dart';

import '../../mocks.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  late MockTokenStorage mockTokenStorage;
  late AuthInterceptor interceptor;
  late MockRequestInterceptorHandler handler;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    interceptor = AuthInterceptor(mockTokenStorage);
    handler = MockRequestInterceptorHandler();
  });

  test('adds Authorization Bearer header when token exists', () async {
    when(() => mockTokenStorage.getToken())
        .thenAnswer((_) async => 'test-token');
    when(() => handler.next(any())).thenReturn(null);

    final options = RequestOptions(path: '/test');
    interceptor.onRequest(options, handler);

    // Allow the async onRequest to complete
    await Future.delayed(Duration.zero);

    expect(options.headers['Authorization'], 'Bearer test-token');
    verify(() => handler.next(options)).called(1);
  });

  test('no Authorization header when token is null', () async {
    when(() => mockTokenStorage.getToken()).thenAnswer((_) async => null);
    when(() => handler.next(any())).thenReturn(null);

    final options = RequestOptions(path: '/test');
    interceptor.onRequest(options, handler);

    await Future.delayed(Duration.zero);

    expect(options.headers.containsKey('Authorization'), false);
    verify(() => handler.next(options)).called(1);
  });

  test('always calls handler.next', () async {
    when(() => mockTokenStorage.getToken()).thenAnswer((_) async => null);
    when(() => handler.next(any())).thenReturn(null);

    final options = RequestOptions(path: '/test');
    interceptor.onRequest(options, handler);

    await Future.delayed(Duration.zero);

    verify(() => handler.next(options)).called(1);
  });
}
