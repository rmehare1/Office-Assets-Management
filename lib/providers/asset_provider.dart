import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';
import '../services/api_exception.dart';

class AssetProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  AssetStatus? _statusFilter;
  AssetCategory? _categoryFilter;
  String _sortField = 'name';
  bool _sortAscending = true;

  AssetProvider(this._apiService);

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  AssetStatus? get statusFilter => _statusFilter;
  AssetCategory? get categoryFilter => _categoryFilter;

  List<Asset> get filteredAssets {
    var result = List<Asset>.from(_assets);

    if (_statusFilter != null) {
      result = result.where((a) => a.status == _statusFilter).toList();
    }
    if (_categoryFilter != null) {
      result = result.where((a) => a.category == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.categoryLabel.toLowerCase().contains(query) ||
            a.location.toLowerCase().contains(query) ||
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
          cmp = a.status.index.compareTo(b.status.index);
        case 'category':
          cmp = a.category.index.compareTo(b.category.index);
        default:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  int get totalAssets => _assets.length;
  int get availableCount =>
      _assets.where((a) => a.status == AssetStatus.available).length;
  int get assignedCount =>
      _assets.where((a) => a.status == AssetStatus.assigned).length;
  int get maintenanceCount =>
      _assets.where((a) => a.status == AssetStatus.maintenance).length;

  Map<AssetCategory, int> get categoryBreakdown {
    final map = <AssetCategory, int>{};
    for (final asset in _assets) {
      map[asset.category] = (map[asset.category] ?? 0) + 1;
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

  void setStatusFilter(AssetStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(AssetCategory? category) {
    _categoryFilter = category;
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
