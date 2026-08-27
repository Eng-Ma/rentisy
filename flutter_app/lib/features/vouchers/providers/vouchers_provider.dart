import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class VouchersProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _vouchers = [];
  Map<String, dynamic>? _currentVoucher;
  String _selectedType = 'all'; // all, receipt, payment

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get vouchers => _vouchers;
  Map<String, dynamic>? get currentVoucher => _currentVoucher;
  String get selectedType => _selectedType;

  void setSelectedType(String type) {
    _selectedType = type;
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (_selectedType != 'all') {
      query['type'] = _selectedType;
    }

    final response = await ApiService.get(ApiEndpoints.vouchers, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _vouchers = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل السندات';
    }

    notifyListeners();
  }

  Future<void> fetchVoucherDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.voucherDetail(id));

    _isLoading = false;

    if (response.success && response.data is Map) {
      _currentVoucher = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل تفاصيل السند';
    }

    notifyListeners();
  }

  Future<bool> createVoucher(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.vouchers, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchVouchers();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حفظ السند';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVoucher(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.voucherDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchVouchers();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف السند';
      notifyListeners();
      return false;
    }
  }
}
