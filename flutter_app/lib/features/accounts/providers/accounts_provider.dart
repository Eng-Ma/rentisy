import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class AccountsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _accounts = [];
  List<dynamic> _currencies = [];
  String _selectedTypeFilter = 'all';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get accounts => _accounts;
  List<dynamic> get currencies => _currencies;
  String get selectedTypeFilter => _selectedTypeFilter;

  List<dynamic> get filteredAccounts {
    if (_selectedTypeFilter == 'all') return _accounts;
    return _accounts.where((a) => a['type'] == _selectedTypeFilter).toList();
  }

  void setTypeFilter(String type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  Future<void> fetchAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.accounts);

    _isLoading = false;

    if (response.success && response.data is List) {
      _accounts = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل شجرة الحسابات';
    }

    notifyListeners();
  }

  Future<void> fetchCurrencies() async {
    final response = await ApiService.get(ApiEndpoints.currencies);
    if (response.success && response.data is List) {
      _currencies = response.data;
      notifyListeners();
    }
  }

  Future<bool> createAccount(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.accounts, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchAccounts();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل إنشاء الحساب';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.put(ApiEndpoints.accountDetail(id), body: data);

    _isLoading = false;

    if (response.success) {
      await fetchAccounts();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تعديل الحساب';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.accountDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchAccounts();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف الحساب';
      notifyListeners();
      return false;
    }
  }
}
