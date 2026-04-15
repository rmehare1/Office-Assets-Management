import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:office_assets_app/models/status.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/api_exception.dart';

class StatusProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Status> _statuses = [];
  bool _isLoading = true;
  String? _error;

  StatusProvider(this._apiService);

  List<Status> get statuses => _statuses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Extract ApiException from DioException.error if present.
  static ApiException? _extractApiException(Object e) {
    if (e is ApiException) return e;
    if (e is DioException && e.error is ApiException) return e.error as ApiException;
    return null;
  }

  Future<void> loadStatuses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statuses = await _apiService.getStatuses();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to load statuses.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStatus(Status status) async {
    try {
      final created = await _apiService.createStatus(status);
      _statuses.add(created);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to add status.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> updateStatus(Status status) async {
    try {
      final updated = await _apiService.updateStatus(status);
      final index = _statuses.indexWhere((s) => s.id == status.id);
      if (index >= 0) {
        _statuses[index] = updated;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to update status.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> deleteStatus(String id) async {
    try {
      await _apiService.deleteStatus(id);
      _statuses.removeWhere((s) => s.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to delete status.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }
}
