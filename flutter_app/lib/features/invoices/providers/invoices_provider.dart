import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class InvoicesProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _invoices = [];
  Map<String, dynamic>? _currentInvoice;
  String _selectedType = 'all'; // all, sale, purchase, sale_return, purchase_return

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get invoices => _invoices;
  Map<String, dynamic>? get currentInvoice => _currentInvoice;
  String get selectedType => _selectedType;

  void setType(String type) {
    _selectedType = type;
    fetchInvoices();
  }

  Future<void> fetchInvoices({String? search, String? date}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (_selectedType != 'all') query['type'] = _selectedType;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (date != null && date.isNotEmpty) query['date'] = date;

    final response = await ApiService.get(ApiEndpoints.invoices, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _invoices = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل قائمة الفواتير';
    }

    notifyListeners();
  }

  Future<void> fetchInvoiceDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.invoiceDetail(id));

    _isLoading = false;

    if (response.success && response.data is Map) {
      _currentInvoice = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل تفاصيل الفاتورة';
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>?> createInvoice(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.invoices, body: data);

    _isLoading = false;

    if (response.success && response.data is Map) {
      await fetchInvoices();
      return response.data as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'فشل حفظ الفاتورة';
      notifyListeners();
      return null;
    }
  }
}
