import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/api_exception.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._apiService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
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
    }
  }
}
