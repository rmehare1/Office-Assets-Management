import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/services/api_exception.dart';

import '../mocks.dart';

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
  );
}

void main() {
  late MockApiService mockApi;
  late AssetProvider provider;

  setUp(() {
    mockApi = MockApiService();
    provider = AssetProvider(mockApi);
  });

  setUpAll(() {
    registerFallbackValue(makeAsset());
  });

  group('loadAssets', () {
    test('success sets assets list and clears error', () async {
      final assets = [makeAsset(id: '1'), makeAsset(id: '2')];
      when(() => mockApi.getAssets()).thenAnswer((_) async => assets);

      await provider.loadAssets();

      expect(provider.assets, hasLength(2));
      expect(provider.error, isNull);
      expect(provider.isLoading, false);
    });

    test('API exception sets error message, assets stays empty', () async {
      when(() => mockApi.getAssets())
          .thenThrow(const ServerException('Server down'));

      await provider.loadAssets();

      expect(provider.error, 'Server down');
      expect(provider.assets, isEmpty);
      expect(provider.isLoading, false);
    });
  });

  group('addAsset', () {
    test('success appends to list', () async {
      final asset = makeAsset();
      when(() => mockApi.createAsset(any())).thenAnswer((_) async => asset);

      await provider.addAsset(asset);

      expect(provider.assets, contains(asset));
    });

    test('API exception sets error and rethrows', () async {
      when(() => mockApi.createAsset(any()))
          .thenThrow(const ServerException('fail'));

      expect(() => provider.addAsset(makeAsset()), throwsA(isA<ServerException>()));
      expect(provider.error, 'fail');
    });
  });

  group('updateAsset', () {
    test('success replaces asset by id in list', () async {
      final original = makeAsset(id: '1', name: 'Old');
      final updated = makeAsset(id: '1', name: 'New');
      when(() => mockApi.getAssets()).thenAnswer((_) async => [original]);
      when(() => mockApi.updateAsset(any())).thenAnswer((_) async => updated);

      await provider.loadAssets();
      await provider.updateAsset(updated);

      expect(provider.assets.first.name, 'New');
    });

    test('id not found causes no crash, list unchanged', () async {
      final existing = makeAsset(id: '1');
      when(() => mockApi.getAssets()).thenAnswer((_) async => [existing]);
      when(() => mockApi.updateAsset(any()))
          .thenAnswer((_) async => makeAsset(id: '999', name: 'Ghost'));

      await provider.loadAssets();
      await provider.updateAsset(makeAsset(id: '999'));

      expect(provider.assets, hasLength(1));
      expect(provider.assets.first.id, '1');
    });
  });

  group('deleteAsset', () {
    test('success removes from list', () async {
      when(() => mockApi.getAssets())
          .thenAnswer((_) async => [makeAsset(id: '1')]);
      when(() => mockApi.deleteAsset(any())).thenAnswer((_) async {});

      await provider.loadAssets();
      await provider.deleteAsset('1');

      expect(provider.assets, isEmpty);
    });

    test('API exception sets error and rethrows', () async {
      when(() => mockApi.deleteAsset(any()))
          .thenThrow(const ServerException('fail'));

      expect(
          () => provider.deleteAsset('1'), throwsA(isA<ServerException>()));
      expect(provider.error, 'fail');
    });
  });

  group('getById', () {
    test('found returns correct Asset', () async {
      when(() => mockApi.getAssets())
          .thenAnswer((_) async => [makeAsset(id: '42', name: 'Found')]);
      await provider.loadAssets();

      expect(provider.getById('42')?.name, 'Found');
    });

    test('not found returns null', () {
      expect(provider.getById('nope'), isNull);
    });
  });

  group('filteredAssets', () {
    setUp(() async {
      final assets = [
        makeAsset(
          id: '1',
          name: 'Alpha Laptop',
          category: AssetCategory.laptop,
          status: AssetStatus.available,
          location: 'Floor 1',
          serialNumber: 'SN-AAA',
          purchasePrice: 500,
          purchaseDate: DateTime(2024, 1, 1),
        ),
        makeAsset(
          id: '2',
          name: 'Beta Monitor',
          category: AssetCategory.monitor,
          status: AssetStatus.assigned,
          location: 'Floor 2',
          serialNumber: 'SN-BBB',
          purchasePrice: 300,
          purchaseDate: DateTime(2024, 6, 1),
        ),
        makeAsset(
          id: '3',
          name: 'Gamma Phone',
          category: AssetCategory.phone,
          status: AssetStatus.available,
          location: 'Floor 1',
          serialNumber: 'SN-CCC',
          purchasePrice: 800,
          purchaseDate: DateTime(2024, 3, 1),
        ),
      ];
      when(() => mockApi.getAssets()).thenAnswer((_) async => assets);
      await provider.loadAssets();
    });

    test('search by name (case-insensitive)', () {
      provider.setSearchQuery('alpha');
      expect(provider.filteredAssets, hasLength(1));
      expect(provider.filteredAssets.first.name, 'Alpha Laptop');
    });

    test('search by location', () {
      provider.setSearchQuery('floor 2');
      expect(provider.filteredAssets, hasLength(1));
      expect(provider.filteredAssets.first.id, '2');
    });

    test('search by serialNumber', () {
      provider.setSearchQuery('SN-CCC');
      expect(provider.filteredAssets, hasLength(1));
      expect(provider.filteredAssets.first.id, '3');
    });

    test('status filter', () {
      provider.setStatusFilter(AssetStatus.assigned);
      expect(provider.filteredAssets, hasLength(1));
      expect(provider.filteredAssets.first.id, '2');
    });

    test('category filter', () {
      provider.setCategoryFilter(AssetCategory.phone);
      expect(provider.filteredAssets, hasLength(1));
      expect(provider.filteredAssets.first.id, '3');
    });

    test('combined filters', () {
      provider.setSearchQuery('floor 1');
      provider.setStatusFilter(AssetStatus.available);
      provider.setCategoryFilter(AssetCategory.laptop);
      expect(provider.filteredAssets, hasLength(1));
      expect(provider.filteredAssets.first.id, '1');
    });

    test('sort by name ascending', () {
      provider.setSort('name', true);
      final names = provider.filteredAssets.map((a) => a.name).toList();
      expect(names, ['Alpha Laptop', 'Beta Monitor', 'Gamma Phone']);
    });

    test('sort by price descending', () {
      provider.setSort('purchase_price', false);
      final prices =
          provider.filteredAssets.map((a) => a.purchasePrice).toList();
      expect(prices, [800, 500, 300]);
    });

    test('sort by date', () {
      provider.setSort('purchase_date', true);
      final ids = provider.filteredAssets.map((a) => a.id).toList();
      expect(ids, ['1', '3', '2']);
    });
  });

  group('statistics', () {
    setUp(() async {
      final assets = [
        makeAsset(id: '1', status: AssetStatus.available, category: AssetCategory.laptop),
        makeAsset(id: '2', status: AssetStatus.assigned, category: AssetCategory.laptop),
        makeAsset(id: '3', status: AssetStatus.available, category: AssetCategory.monitor),
      ];
      when(() => mockApi.getAssets()).thenAnswer((_) async => assets);
      await provider.loadAssets();
    });

    test('totalAssets', () {
      expect(provider.totalAssets, 3);
    });

    test('availableCount', () {
      expect(provider.availableCount, 2);
    });

    test('assignedCount', () {
      expect(provider.assignedCount, 1);
    });

    test('categoryBreakdown', () {
      final breakdown = provider.categoryBreakdown;
      expect(breakdown[AssetCategory.laptop], 2);
      expect(breakdown[AssetCategory.monitor], 1);
    });
  });

  group('setSearchQuery', () {
    test('updates query', () {
      provider.setSearchQuery('hello');
      expect(provider.searchQuery, 'hello');
    });
  });

  group('clearFilters', () {
    test('resets all filters', () {
      provider.setSearchQuery('test');
      provider.setStatusFilter(AssetStatus.available);
      provider.setCategoryFilter(AssetCategory.laptop);

      provider.clearFilters();

      expect(provider.searchQuery, '');
      expect(provider.statusFilter, isNull);
      expect(provider.categoryFilter, isNull);
    });
  });
}
