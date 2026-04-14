import 'package:flutter/material.dart';
import 'package:office_assets_app/models/ticket.dart';
import 'package:office_assets_app/services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Ticket> _tickets = [];
  List<Ticket> _allTickets = [];
  bool _isLoading = false;
  String? _error;

  TicketProvider(this._apiService);

  List<Ticket> get tickets => _tickets;
  List<Ticket> get allTickets => _allTickets;
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

  Future<void> loadAllTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allTickets = await _apiService.getAllTickets();
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

  Future<bool> updateTicket({
    required String id,
    String? type,
    String? assetId,
    String? notes,
  }) async {
    try {
      final updated = await _apiService.updateTicket(
        id,
        type: type,
        assetId: assetId,
        notes: notes,
      );

      final index = _tickets.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tickets[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTicketStatus(String id, String status, {String? reason}) async {
    try {
      final updated = await _apiService.updateTicketStatus(id, status, reason: reason);
      
      // Update in allTickets list
      final allIndex = _allTickets.indexWhere((t) => t.id == id);
      if (allIndex != -1) {
        _allTickets[allIndex] = updated;
      }
      
      // Update in user tickets list if present
      final userIndex = _tickets.indexWhere((t) => t.id == id);
      if (userIndex != -1) {
        _tickets[userIndex] = updated;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelTicket(String id) async {
    try {
      await _apiService.cancelTicket(id);
      
      // Update local state
      final index = _tickets.indexWhere((t) => t.id == id);
      if (index != -1) {
        // Since we mark it as 'closed' in backend
        _tickets[index] = _tickets[index].copyWith(status: 'closed');
      }
      
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
