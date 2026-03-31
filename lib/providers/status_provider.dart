import 'package:flutter/material.dart';
import '../models/status.dart';
import '../services/api_service.dart';
import '../services/api_exception.dart';

class StatusProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Status> _statuses = [];
  bool _isLoading = false;
  String? _error;

  StatusProvider(this._apiService);

  List<Status> get statuses => _statuses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStatuses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statuses = await _apiService.getStatuses();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
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
    }
  }
}
