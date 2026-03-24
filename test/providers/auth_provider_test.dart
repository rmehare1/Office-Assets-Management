import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/services/api_exception.dart';

import '../mocks.dart';

void main() {
  late MockApiService mockApi;
  late AuthProvider provider;

  setUp(() {
    mockApi = MockApiService();
    provider = AuthProvider(mockApi);
  });

  test('initial state', () {
    expect(provider.isAuthenticated, false);
    expect(provider.currentUser, isNull);
    expect(provider.error, isNull);
    expect(provider.isLoading, false);
  });

  group('login', () {
    test('success sets currentUser and isAuthenticated', () async {
      when(() => mockApi.login(any(), any())).thenAnswer((_) async => {
            'token': 'abc',
            'user': {
              'id': '1',
              'name': 'Test User',
              'email': 'test@test.com',
              'department': 'Eng',
              'role': 'Dev',
              'phone': '555',
              'assigned_assets': 0,
              'join_date': '2023-01-01',
            },
          });

      final result = await provider.login('test@test.com', 'pass');

      expect(result, true);
      expect(provider.isAuthenticated, true);
      expect(provider.currentUser?.name, 'Test User');
      expect(provider.error, isNull);
      expect(provider.isLoading, false);
    });

    test('NetworkException sets specific network error message', () async {
      when(() => mockApi.login(any(), any()))
          .thenThrow(const NetworkException());

      final result = await provider.login('test@test.com', 'pass');

      expect(result, false);
      expect(provider.error,
          'No internet connection. Please check your network.');
      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
    });

    test('ApiException sets e.message as error', () async {
      when(() => mockApi.login(any(), any()))
          .thenThrow(const UnauthorizedException('Bad credentials'));

      final result = await provider.login('test@test.com', 'pass');

      expect(result, false);
      expect(provider.error, 'Bad credentials');
      expect(provider.isLoading, false);
    });

    test('isLoading transitions', () async {
      when(() => mockApi.login(any(), any())).thenAnswer((_) async {
        expect(provider.isLoading, true);
        return {
          'token': 'abc',
          'user': {
            'id': '1',
            'name': 'Test',
            'email': 't@t.com',
            'department': 'D',
            'role': 'R',
            'phone': '',
            'assigned_assets': 0,
            'join_date': '2023-01-01',
          },
        };
      });

      expect(provider.isLoading, false);
      await provider.login('a', 'b');
      expect(provider.isLoading, false);
    });
  });

  test('logout clears user, auth, error and calls setToken(null)', () async {
    // First login
    when(() => mockApi.login(any(), any())).thenAnswer((_) async => {
          'token': 'abc',
          'user': {
            'id': '1',
            'name': 'Test',
            'email': 't@t.com',
            'department': 'D',
            'role': 'R',
            'phone': '',
            'assigned_assets': 0,
            'join_date': '2023-01-01',
          },
        });
    when(() => mockApi.setToken(any())).thenReturn(null);

    await provider.login('a', 'b');
    provider.logout();

    expect(provider.currentUser, isNull);
    expect(provider.isAuthenticated, false);
    expect(provider.error, isNull);
    verify(() => mockApi.setToken(null)).called(1);
  });

  test('clearError sets error to null', () async {
    when(() => mockApi.login(any(), any()))
        .thenThrow(const NetworkException());

    await provider.login('a', 'b');
    expect(provider.error, isNotNull);

    provider.clearError();
    expect(provider.error, isNull);
  });
}
