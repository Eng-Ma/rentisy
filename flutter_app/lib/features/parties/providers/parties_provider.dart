import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class PartiesProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _parties = [];
  String _selectedType = 'all'; // all, customer, vendor

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get parties => _parties;
  String get selectedType => _selectedType;

  List<dynamic> get customers => _parties.where((p) => p['type'] == 'customer').toList();
  List<dynamic> get vendors => _parties.where((p) => p['type'] == 'vendor').toList();

  void setType(String type) {
    _selectedType = type;
    fetchParties();
  }

  Future<void> fetchParties({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (_selectedType != 'all') query['type'] = _selectedType;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await ApiService.get(ApiEndpoints.parties, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _parties = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل قائمة العملاء والموردين';
    }

    notifyListeners();
  }

  Future<bool> createParty(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.parties, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchParties();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل إضافة الطرف';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateParty(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.put(ApiEndpoints.partyDetail(id), body: data);

    _isLoading = false;

    if (response.success) {
      await fetchParties();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تعديل الطرف';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteParty(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.partyDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchParties();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف الطرف';
      notifyListeners();
      return false;
    }
  }
}
