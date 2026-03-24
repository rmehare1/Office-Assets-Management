import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_assets_app/models/user.dart';
import 'package:office_assets_app/providers/user_provider.dart';

import '../mocks.dart';

void main() {
  late MockApiService mockApi;
  late UserProvider provider;

  setUp(() {
    mockApi = MockApiService();
    provider = UserProvider(mockApi);
  });

  test('initial state: users empty, isLoading false', () {
    expect(provider.users, isEmpty);
    expect(provider.isLoading, false);
  });

  test('loadUsers success sets users list', () async {
    final users = [
      AppUser(
        id: '1',
        name: 'Alice',
        email: 'alice@test.com',
        department: 'Eng',
        role: 'Dev',
        phone: '123',
        assignedAssets: 2,
        joinDate: DateTime(2023, 1, 1),
      ),
    ];
    when(() => mockApi.getUsers()).thenAnswer((_) async => users);

    await provider.loadUsers();

    expect(provider.users, hasLength(1));
    expect(provider.users.first.name, 'Alice');
    expect(provider.isLoading, false);
  });

  test('loadUsers exception: silently fails, users stays empty', () async {
    when(() => mockApi.getUsers()).thenThrow(Exception('fail'));

    await provider.loadUsers();

    expect(provider.users, isEmpty);
    expect(provider.isLoading, false);
  });
}
