import 'package:flutter/material.dart';
import 'package:office_assets_app/models/ticket.dart';
import 'package:office_assets_app/services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _error;

  TicketProvider(this._apiService);

  List<Ticket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _apiService.getUserTickets();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTicket({
    required String type,
    String? assetId,
    String? notes,
  }) async {
    try {
      final ticket = await _apiService.createTicket(
        type: type,
        assetId: assetId,
        notes: notes,
      );
      _tickets.insert(0, ticket);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
