import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'auth_token';
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _key);

  Future<void> setToken(String token) => _storage.write(key: _key, value: token);

  Future<void> clearToken() => _storage.delete(key: _key);
}
