import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/token_storage.dart';

class MockApiService extends Mock implements ApiService {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
