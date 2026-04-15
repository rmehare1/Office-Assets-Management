import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:office_assets_app/models/maintenance_alert.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/api_exception.dart';

class AlertProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<MaintenanceAlert> _alerts = [];
  bool _isLoading = true;
  String? _error;

  AlertProvider(this._apiService);

  List<MaintenanceAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static ApiException? _extractApiException(Object e) {
    if (e is ApiException) return e;
    if (e is DioException && e.error is ApiException) return e.error as ApiException;
    return null;
  }

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _apiService.getAlerts();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to load alerts.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAlertStatus(String id, String status) async {
    try {
      final updated = await _apiService.updateAlertStatus(id, status);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index >= 0) {
        _alerts[index] = updated;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to update alert.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }
}
