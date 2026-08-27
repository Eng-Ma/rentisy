import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class InventoryProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _items = [];
  List<dynamic> _categories = [];
  List<dynamic> _stores = [];
  List<dynamic> _stockTransfers = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get items => _items;
  List<dynamic> get categories => _categories;
  List<dynamic> get stores => _stores;
  List<dynamic> get stockTransfers => _stockTransfers;

  Future<void> fetchItems({String? search, int? categoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (categoryId != null) query['category_id'] = categoryId;

    final response = await ApiService.get(ApiEndpoints.items, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _items = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل قائمة الأصناف';
    }

    notifyListeners();
  }

  Future<void> fetchCategories() async {
    final response = await ApiService.get(ApiEndpoints.categories);
    if (response.success && response.data is List) {
      _categories = response.data;
      notifyListeners();
    }
  }

  Future<void> fetchStores() async {
    final response = await ApiService.get(ApiEndpoints.stores);
    if (response.success && response.data is List) {
      _stores = response.data;
      notifyListeners();
    }
  }

  Future<void> fetchStockTransfers({String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (type != null && type.isNotEmpty && type != 'all') query['type'] = type;

    final response = await ApiService.get(ApiEndpoints.stockTransfers, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _stockTransfers = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل حركات المخزون';
    }

    notifyListeners();
  }

  Future<bool> createItem(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.items, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchItems();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل إضافة الصنف';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.put(ApiEndpoints.itemDetail(id), body: data);

    _isLoading = false;

    if (response.success) {
      await fetchItems();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تعديل الصنف';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.itemDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchItems();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حذف الصنف';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiEndpoints.categories, body: data);
    if (response.success) {
      await fetchCategories();
      return true;
    }
    return false;
  }

  Future<bool> createStore(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiEndpoints.stores, body: data);
    if (response.success) {
      await fetchStores();
      return true;
    }
    return false;
  }

  Future<bool> createStockTransfer(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.stockTransfers, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchStockTransfers();
      await fetchItems();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حفظ حركة المخزون';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStockTransfer(int id) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.delete(ApiEndpoints.stockTransferDetail(id));

    _isLoading = false;

    if (response.success) {
      await fetchStockTransfers();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل إلغاء حركة المخزون';
      notifyListeners();
      return false;
    }
  }
}
