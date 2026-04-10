import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:office_assets_app/models/department.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/api_exception.dart';

class DepartmentProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;

  DepartmentProvider(this._apiService);

  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static ApiException? _extractApiException(Object e) {
    if (e is ApiException) return e;
    if (e is DioException && e.error is ApiException) return e.error as ApiException;
    return null;
  }

  Future<void> loadDepartments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _departments = await _apiService.getDepartments();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to load departments.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDepartment(Department department) async {
    try {
      final created = await _apiService.createDepartment(department);
      _departments.add(created);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to add department.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> updateDepartment(Department department) async {
    try {
      final updated = await _apiService.updateDepartment(department);
      final index = _departments.indexWhere((d) => d.id == department.id);
      if (index >= 0) {
        _departments[index] = updated;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to update department.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> deleteDepartment(String id) async {
    try {
      await _apiService.deleteDepartment(id);
      _departments.removeWhere((d) => d.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to delete department.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }
}
