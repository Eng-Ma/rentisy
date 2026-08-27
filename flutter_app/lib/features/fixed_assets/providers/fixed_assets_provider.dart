import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class FixedAssetsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _assets = [];
  Map<String, dynamic>? _currentAsset;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get assets => _assets;
  Map<String, dynamic>? get currentAsset => _currentAsset;

  Future<void> fetchFixedAssets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.fixedAssets);

    _isLoading = false;

    if (response.success && response.data is List) {
      _assets = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل سجل الأصول الثابتة';
    }

    notifyListeners();
  }

  Future<void> fetchAssetDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.fixedAssetDetail(id));

    _isLoading = false;

    if (response.success && response.data is Map) {
      _currentAsset = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل تفاصيل الأصل';
    }

    notifyListeners();
  }

  Future<bool> createFixedAsset(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.fixedAssets, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchFixedAssets();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تسجيل الأصل الثابت';
      notifyListeners();
      return false;
    }
  }

  Future<bool> depreciateAsset(int assetId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.depreciateAsset(assetId), body: data);

    _isLoading = false;

    if (response.success) {
      await fetchFixedAssets();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل احتساب الإهلاك';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFixedAsset(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.fixedAssetDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchFixedAssets();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف الأصل الثابت';
      notifyListeners();
      return false;
    }
  }
}
