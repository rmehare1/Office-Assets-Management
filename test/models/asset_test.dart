import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_assets_app/models/asset.dart';

void main() {
  group('assetStatusFromString', () {
    test('returns correct enum for each valid value', () {
      expect(assetStatusFromString('available'), AssetStatus.available);
      expect(assetStatusFromString('assigned'), AssetStatus.assigned);
      expect(assetStatusFromString('maintenance'), AssetStatus.maintenance);
      expect(assetStatusFromString('retired'), AssetStatus.retired);
    });

    test('returns available for invalid or empty string', () {
      expect(assetStatusFromString('invalid'), AssetStatus.available);
      expect(assetStatusFromString(''), AssetStatus.available);
    });
  });

  group('assetCategoryFromString', () {
    test('returns correct enum for each valid value', () {
      expect(assetCategoryFromString('laptop'), AssetCategory.laptop);
      expect(assetCategoryFromString('monitor'), AssetCategory.monitor);
      expect(assetCategoryFromString('phone'), AssetCategory.phone);
      expect(assetCategoryFromString('furniture'), AssetCategory.furniture);
      expect(assetCategoryFromString('accessory'), AssetCategory.accessory);
      expect(assetCategoryFromString('other'), AssetCategory.other);
    });

    test('returns other for invalid or empty string', () {
      expect(assetCategoryFromString('invalid'), AssetCategory.other);
      expect(assetCategoryFromString(''), AssetCategory.other);
    });
  });

  Asset makeAsset({
    String id = '1',
    String name = 'Test Laptop',
    AssetCategory category = AssetCategory.laptop,
    AssetStatus status = AssetStatus.available,
    String assignedTo = '',
    String serialNumber = 'SN-001',
    String location = 'Office A',
    DateTime? purchaseDate,
    double purchasePrice = 999.99,
    String? imageUrl,
    String? notes,
  }) {
    return Asset(
      id: id,
      name: name,
      category: category,
      status: status,
      assignedTo: assignedTo,
      serialNumber: serialNumber,
      location: location,
      purchaseDate: purchaseDate ?? DateTime(2024, 1, 15),
      purchasePrice: purchasePrice,
      imageUrl: imageUrl,
      notes: notes,
    );
  }

  group('Asset.fromJson', () {
    test('parses complete JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'MacBook Pro',
        'category': 'laptop',
        'status': 'assigned',
        'assigned_to_name': 'John Doe',
        'assigned_to': 'user-123',
        'serial_number': 'SN-123',
        'location': 'Floor 2',
        'purchase_date': '2024-01-15',
        'purchase_price': '1299.99',
        'image_url': 'https://example.com/img.png',
        'notes': 'Company laptop',
      };

      final asset = Asset.fromJson(json);

      expect(asset.id, '1');
      expect(asset.name, 'MacBook Pro');
      expect(asset.category, AssetCategory.laptop);
      expect(asset.status, AssetStatus.assigned);
      expect(asset.assignedTo, 'John Doe');
      expect(asset.serialNumber, 'SN-123');
      expect(asset.location, 'Floor 2');
      expect(asset.purchaseDate, DateTime(2024, 1, 15));
      expect(asset.purchasePrice, 1299.99);
      expect(asset.imageUrl, 'https://example.com/img.png');
      expect(asset.notes, 'Company laptop');
    });

    test('prefers assigned_to_name, falls back to assigned_to', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'category': 'laptop',
        'status': 'available',
        'assigned_to': 'user-456',
        'serial_number': 'SN-1',
        'location': 'A',
        'purchase_date': '2024-01-01',
        'purchase_price': '100',
      };
      expect(Asset.fromJson(json).assignedTo, 'user-456');
    });

    test('null optional fields', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'category': 'laptop',
        'status': 'available',
        'serial_number': 'SN-1',
        'location': 'A',
        'purchase_date': '2024-01-01',
        'purchase_price': '100',
      };
      final asset = Asset.fromJson(json);
      expect(asset.imageUrl, isNull);
      expect(asset.notes, isNull);
      expect(asset.assignedTo, '');
    });

    test('price as int', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'category': 'laptop',
        'status': 'available',
        'serial_number': 'SN-1',
        'location': 'A',
        'purchase_date': '2024-01-01',
        'purchase_price': 500,
      };
      expect(Asset.fromJson(json).purchasePrice, 500.0);
    });
  });

  group('Asset.toJson', () {
    test('round-trip produces equivalent Asset', () {
      final original = makeAsset(assignedTo: 'John', notes: 'test');
      final restored = Asset.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.status, original.status);
      expect(restored.assignedTo, original.assignedTo);
      expect(restored.serialNumber, original.serialNumber);
      expect(restored.location, original.location);
      expect(restored.purchaseDate, original.purchaseDate);
      expect(restored.purchasePrice, original.purchasePrice);
      expect(restored.notes, original.notes);
    });

    test('empty assignedTo becomes null', () {
      final asset = makeAsset(assignedTo: '');
      expect(asset.toJson()['assigned_to'], isNull);
    });

    test('date format is ISO-8601 date only', () {
      final asset = makeAsset(purchaseDate: DateTime(2024, 3, 5));
      expect(asset.toJson()['purchase_date'], '2024-03-05');
    });
  });

  group('Asset.copyWith', () {
    test('partial update changes only specified fields', () {
      final original = makeAsset();
      final updated = original.copyWith(name: 'New Name', purchasePrice: 500.0);

      expect(updated.name, 'New Name');
      expect(updated.purchasePrice, 500.0);
      expect(updated.id, original.id);
      expect(updated.category, original.category);
      expect(updated.status, original.status);
    });

    test('no args returns identical copy', () {
      final original = makeAsset();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.category, original.category);
      expect(copy.status, original.status);
      expect(copy.purchasePrice, original.purchasePrice);
    });
  });

  group('statusColor', () {
    test('returns correct Color for each status', () {
      expect(makeAsset(status: AssetStatus.available).statusColor,
          const Color(0xFF27AE60));
      expect(makeAsset(status: AssetStatus.assigned).statusColor,
          const Color(0xFF4A90D9));
      expect(makeAsset(status: AssetStatus.maintenance).statusColor,
          const Color(0xFFE67E22));
      expect(makeAsset(status: AssetStatus.retired).statusColor,
          const Color(0xFFE74C3C));
    });
  });

  group('statusLabel', () {
    test('returns correct label for each status', () {
      expect(
          makeAsset(status: AssetStatus.available).statusLabel, 'Available');
      expect(makeAsset(status: AssetStatus.assigned).statusLabel, 'Assigned');
      expect(makeAsset(status: AssetStatus.maintenance).statusLabel,
          'Maintenance');
      expect(makeAsset(status: AssetStatus.retired).statusLabel, 'Retired');
    });
  });

  group('categoryLabel', () {
    test('returns correct label for each category', () {
      expect(makeAsset(category: AssetCategory.laptop).categoryLabel, 'Laptop');
      expect(
          makeAsset(category: AssetCategory.monitor).categoryLabel, 'Monitor');
      expect(makeAsset(category: AssetCategory.phone).categoryLabel, 'Phone');
      expect(makeAsset(category: AssetCategory.furniture).categoryLabel,
          'Furniture');
      expect(makeAsset(category: AssetCategory.accessory).categoryLabel,
          'Accessory');
      expect(makeAsset(category: AssetCategory.other).categoryLabel, 'Other');
    });
  });

  group('categoryIcon', () {
    test('returns correct IconData for each category', () {
      expect(makeAsset(category: AssetCategory.laptop).categoryIcon,
          Icons.laptop_mac);
      expect(makeAsset(category: AssetCategory.monitor).categoryIcon,
          Icons.monitor);
      expect(makeAsset(category: AssetCategory.phone).categoryIcon,
          Icons.phone_android);
      expect(makeAsset(category: AssetCategory.furniture).categoryIcon,
          Icons.chair);
      expect(makeAsset(category: AssetCategory.accessory).categoryIcon,
          Icons.headphones);
      expect(makeAsset(category: AssetCategory.other).categoryIcon,
          Icons.devices_other);
    });
  });
}
