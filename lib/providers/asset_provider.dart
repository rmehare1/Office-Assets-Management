import 'package:flutter/material.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/api_exception.dart';

class AssetProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Asset> _assets = [];
  List<Asset> _userAssets = [];
  bool _isLoading = false;
  String? _error = null;
  String _searchQuery = '';
  String? _statusFilter;
  String? _categoryFilter;
  String _sortField = 'name';
  bool _sortAscending = true;

  AssetProvider(this._apiService);

  List<Asset> get assets => _assets;
  List<Asset> get userAssets => _userAssets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;

  List<Asset> get filteredAssets {
    var result = List<Asset>.from(_assets);

    if (_statusFilter != null) {
      result = result.where((a) => a.statusId == _statusFilter).toList();
    }
    if (_categoryFilter != null) {
      result = result.where((a) => a.categoryId == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.categoryLabel.toLowerCase().contains(query) ||
            a.locationName.toLowerCase().contains(query) ||
            a.serialNumber.toLowerCase().contains(query);
      }).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'purchase_price':
          cmp = a.purchasePrice.compareTo(b.purchasePrice);
        case 'purchase_date':
          cmp = a.purchaseDate.compareTo(b.purchaseDate);
        case 'status':
          cmp = a.statusName.compareTo(b.statusName);
        case 'category':
          cmp = a.categoryName.compareTo(b.categoryName);
        default:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  int get totalAssets => _assets.length;
  int get availableCount =>
      _assets.where((a) => a.statusName.toLowerCase() == 'available').length;
  int get assignedCount =>
      _assets.where((a) => a.statusName.toLowerCase() == 'assigned').length;
  int get maintenanceCount =>
      _assets.where((a) => a.statusName.toLowerCase() == 'maintenance').length;
  int get decommissionedCount =>
      _assets.where((a) => a.statusName.toLowerCase() == 'decommissioned').length;

  Map<String, int> get categoryBreakdown {
    final map = <String, int>{};
    for (final asset in _assets) {
      map[asset.categoryName] = (map[asset.categoryName] ?? 0) + 1;
    }
    return map;
  }

  Asset? getById(String id) {
    try {
      return _assets.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await _apiService.getAssets();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserAssets(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userAssets = await _apiService.getAssets(assignedToUserId: userId);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lookup an asset by scanned barcode/QR code.
  /// Returns null if no matching asset is found.
  Future<Asset?> lookupByCode(String code) async {
    try {
      return await _apiService.lookupAssetByCode(code);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> addAsset(Asset asset) async {
    try {
      final created = await _apiService.createAsset(asset);
      _assets.add(created);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAsset(Asset asset) async {
    try {
      final updated = await _apiService.updateAsset(asset);
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index >= 0) {
        _assets[index] = updated;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> decommissionAsset({
    required Asset asset,
    required String method,
    required String recycler,
    required String cert,
  }) async {
    try {
      final decommissioningAsset = asset.copyWith(
        statusId: 'stat_5', // Decommissioned status ID
        statusName: 'Decommissioned',
        decommissionedAt: DateTime.now(),
        decommissionMethod: method,
        recyclerName: recycler,
        certificateNumber: cert,
        assignedTo: '', // Unassign on decommission
      );

      final updated = await _apiService.updateAsset(decommissioningAsset);
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index >= 0) {
        _assets[index] = updated;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _apiService.deleteAsset(id);
      _assets.removeWhere((a) => a.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? statusId) {
    _statusFilter = statusId;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _categoryFilter = categoryId;
    notifyListeners();
  }

  void setSort(String field, bool ascending) {
    _sortField = field;
    _sortAscending = ascending;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }
}
