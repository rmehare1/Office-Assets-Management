import 'package:flutter_test/flutter_test.dart';
import 'package:office_assets_app/services/api_exception.dart';

void main() {
  group('NetworkException', () {
    test('defaults', () {
      const e = NetworkException();
      expect(e.message, 'No internet connection');
      expect(e.statusCode, 0);
    });
  });

  group('UnauthorizedException', () {
    test('defaults', () {
      const e = UnauthorizedException();
      expect(e.message, contains('Session expired'));
      expect(e.statusCode, 401);
    });
  });

  group('ForbiddenException', () {
    test('defaults', () {
      const e = ForbiddenException();
      expect(e.statusCode, 403);
    });
  });

  group('NotFoundException', () {
    test('defaults', () {
      const e = NotFoundException();
      expect(e.statusCode, 404);
    });
  });

  group('ValidationException', () {
    test('stores errors map correctly', () {
      const errors = {'email': 'invalid'};
      const e = ValidationException('Bad input', 422, errors);
      expect(e.message, 'Bad input');
      expect(e.statusCode, 422);
      expect(e.errors, errors);
    });
  });

  group('ServerException', () {
    test('default statusCode is 500', () {
      const e = ServerException();
      expect(e.statusCode, 500);
    });
  });

  group('toString', () {
    test('format is RuntimeType(statusCode): message', () {
      const e = NetworkException();
      expect(e.toString(), 'NetworkException(0): No internet connection');
    });
  });
}
