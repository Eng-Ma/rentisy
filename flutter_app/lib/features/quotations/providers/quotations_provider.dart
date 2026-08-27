import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class QuotationsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _quotations = [];
  Map<String, dynamic>? _currentQuotation;
  String _selectedStatus = 'all';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get quotations => _quotations;
  Map<String, dynamic>? get currentQuotation => _currentQuotation;
  String get selectedStatus => _selectedStatus;

  void setStatus(String status) {
    _selectedStatus = status;
    fetchQuotations();
  }

  Future<void> fetchQuotations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (_selectedStatus != 'all') query['status'] = _selectedStatus;

    final response = await ApiService.get(ApiEndpoints.quotations, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _quotations = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل عروض الأسعار';
    }

    notifyListeners();
  }

  Future<void> fetchQuotationDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.quotationDetail(id));

    _isLoading = false;

    if (response.success && response.data is Map) {
      _currentQuotation = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل تفاصيل عرض السعر';
    }

    notifyListeners();
  }

  Future<bool> createQuotation(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.quotations, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchQuotations();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل إنشاء عرض السعر';
      notifyListeners();
      return false;
    }
  }

  Future<bool> convertToInvoice(int quotationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.convertQuotation(quotationId));

    _isLoading = false;

    if (response.success) {
      await fetchQuotations();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تحويل عرض السعر إلى فاتورة';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteQuotation(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.quotationDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchQuotations();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف عرض السعر';
      notifyListeners();
      return false;
    }
  }
}
