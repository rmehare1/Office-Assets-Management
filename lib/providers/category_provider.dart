import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:office_assets_app/models/category.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/api_exception.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  CategoryProvider(this._apiService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Extract ApiException from DioException.error if present.
  static ApiException? _extractApiException(Object e) {
    if (e is ApiException) return e;
    if (e is DioException && e.error is ApiException) return e.error as ApiException;
    return null;
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to load categories.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      final created = await _apiService.createCategory(category);
      _categories.add(created);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to add category.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      final updated = await _apiService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index >= 0) {
        _categories[index] = updated;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to update category.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _apiService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to delete category.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }
}
