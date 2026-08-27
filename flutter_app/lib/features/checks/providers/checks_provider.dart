import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class ChecksProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _checks = [];
  Map<String, dynamic>? _stats;
  String _selectedType = 'all'; // all, received, issued
  String _selectedStatus = 'all';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get checks => _checks;
  Map<String, dynamic>? get stats => _stats;
  String get selectedType => _selectedType;
  String get selectedStatus => _selectedStatus;

  void setType(String type) {
    _selectedType = type;
    fetchChecks();
  }

  void setStatus(String status) {
    _selectedStatus = status;
    fetchChecks();
  }

  Future<void> fetchChecks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (_selectedType != 'all') query['type'] = _selectedType;
    if (_selectedStatus != 'all') query['status'] = _selectedStatus;

    final response = await ApiService.get(ApiEndpoints.checks, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _checks = response.data;
      if (response.rawJson is Map && response.rawJson['stats'] != null) {
        _stats = response.rawJson['stats'];
      }
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل حافظة الشيكات';
    }

    notifyListeners();
  }

  Future<bool> createCheck(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.checks, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchChecks();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حفظ الشيك';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCheckStatus(int checkId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.checkStatus(checkId), body: data);

    _isLoading = false;

    if (response.success) {
      await fetchChecks();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تحديث حالة الشيك';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCheck(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.checkDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchChecks();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف الشيك';
      notifyListeners();
      return false;
    }
  }
}
