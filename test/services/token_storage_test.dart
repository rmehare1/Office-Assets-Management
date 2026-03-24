import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_assets_app/services/token_storage.dart';

import '../mocks.dart';

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockStorage);
  });

  test('setToken calls storage.write with correct key/value', () async {
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await tokenStorage.setToken('my-token');

    verify(() => mockStorage.write(key: 'auth_token', value: 'my-token')).called(1);
  });

  test('getToken calls storage.read with correct key', () async {
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'stored-token');

    final result = await tokenStorage.getToken();

    expect(result, 'stored-token');
    verify(() => mockStorage.read(key: 'auth_token')).called(1);
  });

  test('clearToken calls storage.delete with correct key', () async {
    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    await tokenStorage.clearToken();

    verify(() => mockStorage.delete(key: 'auth_token')).called(1);
  });
}
