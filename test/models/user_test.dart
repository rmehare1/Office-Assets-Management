import 'package:flutter_test/flutter_test.dart';
import 'package:office_assets_app/models/user.dart';

void main() {
  AppUser makeUser({
    String id = '1',
    String name = 'Jane Doe',
    String email = 'jane@example.com',
    String department = 'Engineering',
    String role = 'Developer',
    String phone = '555-1234',
    String? avatarUrl,
    int assignedAssets = 3,
    DateTime? joinDate,
  }) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      department: department,
      role: role,
      phone: phone,
      avatarUrl: avatarUrl,
      assignedAssets: assignedAssets,
      joinDate: joinDate ?? DateTime(2023, 6, 1),
    );
  }

  group('AppUser.fromJson', () {
    test('parses complete JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'department': 'Engineering',
        'role': 'Developer',
        'phone': '555-1234',
        'avatar_url': 'https://example.com/avatar.png',
        'assigned_assets': 3,
        'join_date': '2023-06-01',
      };
      final user = AppUser.fromJson(json);

      expect(user.id, '1');
      expect(user.name, 'Jane Doe');
      expect(user.email, 'jane@example.com');
      expect(user.department, 'Engineering');
      expect(user.role, 'Developer');
      expect(user.phone, '555-1234');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.assignedAssets, 3);
      expect(user.joinDate, DateTime(2023, 6, 1));
    });

    test('null phone defaults to empty string', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'email': 'test@test.com',
        'department': 'HR',
        'role': 'Manager',
        'assigned_assets': 0,
        'join_date': '2023-01-01',
      };
      expect(AppUser.fromJson(json).phone, '');
    });

    test('assignedAssets as double via num.toInt()', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'email': 'test@test.com',
        'department': 'HR',
        'role': 'Manager',
        'phone': '123',
        'assigned_assets': 5.0,
        'join_date': '2023-01-01',
      };
      expect(AppUser.fromJson(json).assignedAssets, 5);
    });
  });

  group('AppUser.toJson', () {
    test('round-trip produces equivalent AppUser', () {
      final original = makeUser(avatarUrl: 'https://img.com/a.png');
      final restored = AppUser.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.department, original.department);
      expect(restored.role, original.role);
      expect(restored.phone, original.phone);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.assignedAssets, original.assignedAssets);
      expect(restored.joinDate, original.joinDate);
    });

    test('join_date is ISO-8601 date only', () {
      final user = makeUser(joinDate: DateTime(2023, 12, 25));
      expect(user.toJson()['join_date'], '2023-12-25');
    });
  });

  group('AppUser.copyWith', () {
    test('partial update changes only specified fields', () {
      final original = makeUser();
      final updated = original.copyWith(name: 'New Name', assignedAssets: 10);

      expect(updated.name, 'New Name');
      expect(updated.assignedAssets, 10);
      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.department, original.department);
    });
  });
}
