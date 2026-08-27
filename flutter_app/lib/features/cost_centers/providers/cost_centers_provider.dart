import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class CostCentersProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _costCenters = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get costCenters => _costCenters;

  Future<void> fetchCostCenters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.costCenters);

    _isLoading = false;

    if (response.success && response.data is List) {
      _costCenters = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل مراكز التكلفة';
    }

    notifyListeners();
  }

  Future<bool> createCostCenter(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.costCenters, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchCostCenters();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل إنشاء مركز التكلفة';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCostCenter(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.put(ApiEndpoints.costCenterDetail(id), body: data);

    _isLoading = false;

    if (response.success) {
      await fetchCostCenters();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تعديل مركز التكلفة';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCostCenter(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.costCenterDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchCostCenters();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف مركز التكلفة';
      notifyListeners();
      return false;
    }
  }
}
