import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/api_request_service.dart';

class RequestProvider with ChangeNotifier {
  final ApiRequestService _apiService = ApiRequestService();
  List<RequestModel> _requests = [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 0;
  RequestStatus? _statusFilter;

  List<RequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  RequestStatus? get statusFilter => _statusFilter;

  void setStatusFilter(RequestStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<void> fetchAdminRequests(String token, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _requests = [];
    }

    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getAllAdminRequests(
        token: token,
        status: _statusFilter,
        page: _currentPage,
      );

      _totalPages = response.totalPages;
      if (refresh) {
        _requests = response.content;
      } else {
        _requests.addAll(response.content);
      }

      if (_currentPage < _totalPages) {
        _currentPage++;
      }
    } catch (e) {
      print('Error fetching admin requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRequestStatus(
    String token,
    int requestId,
    RequestStatus status,
    String? responseText,
  ) async {
    try {
      final updatedRequest = await _apiService.updateStatus(
        token: token,
        requestId: requestId,
        status: status,
        responseText: responseText,
      );

      // Update local state
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updatedRequest;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating request status: $e');
      rethrow;
    }
  }
}
