import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<AppUser> _users = [];
  bool _isLoading = false;

  UserProvider(this._apiService);

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _apiService.getUsers();
    } catch (_) {
      // Silently fail — dropdown will just be empty
    }

    _isLoading = false;
    notifyListeners();
  }
}
