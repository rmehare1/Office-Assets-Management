import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:office_assets_app/models/location.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/api_exception.dart';

class LocationProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Location> _locations = [];
  bool _isLoading = true;
  String? _error;

  LocationProvider(this._apiService);

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static ApiException? _extractApiException(Object e) {
    if (e is ApiException) return e;
    if (e is DioException && e.error is ApiException) return e.error as ApiException;
    return null;
  }

  Future<void> loadLocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _locations = await _apiService.getLocations();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to load locations.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLocation(Location location) async {
    try {
      final created = await _apiService.createLocation(location);
      _locations.add(created);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to add location.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> updateLocation(Location location) async {
    try {
      final updated = await _apiService.updateLocation(location);
      final index = _locations.indexWhere((l) => l.id == location.id);
      if (index >= 0) {
        _locations[index] = updated;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to update location.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _apiService.deleteLocation(id);
      _locations.removeWhere((l) => l.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      final apiEx = _extractApiException(e);
      _error = apiEx?.message ?? 'Failed to delete location.';
      notifyListeners();
      if (apiEx != null) throw apiEx;
      rethrow;
    }
  }
}
