import 'package:flutter/material.dart';
import 'package:office_assets_app/models/user.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/services/api_exception.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  AppUser? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService);

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiService get apiService => _apiService;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.login(email, password);
      _currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _isAuthenticated = true;
      return true;
    } on NetworkException {
      _error = 'No internet connection. Please check your network.';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String? department,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.register(
        name,
        email,
        password,
        department: department,
      );
      _currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _isAuthenticated = true;
      return true;
    } on NetworkException {
      _error = 'No internet connection. Please check your network.';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(
    String name, {
    String? phone,
    String? department,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.updateProfile(
        name,
        phone: phone,
        department: department,
        email: email,
      );
      _currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      return true;
    } on NetworkException {
      _error = 'No internet connection.';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.changePassword(currentPassword, newPassword);
      return true;
    } on NetworkException {
      _error = 'No internet connection.';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    _apiService.setToken(null);
    notifyListeners();
  }

  Future<String?> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.forgotPassword(email);
      // Return the OTP in dev mode so the user can see it in UI
      return data['otp'];
    } on NetworkException {
      _error = 'No internet connection.';
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.resetPassword(email, token, newPassword);
      return true;
    } on NetworkException {
      _error = 'No internet connection.';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
