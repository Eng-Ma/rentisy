import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class JournalEntriesProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _entries = [];
  Map<String, dynamic>? _currentEntry;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get entries => _entries;
  Map<String, dynamic>? get currentEntry => _currentEntry;

  Future<void> fetchJournalEntries({String? search, String? date}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (date != null && date.isNotEmpty) query['date'] = date;

    final response = await ApiService.get(ApiEndpoints.journalEntries, queryParams: query);

    _isLoading = false;

    if (response.success && response.data is List) {
      _entries = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل قيود اليومية';
    }

    notifyListeners();
  }

  Future<void> fetchEntryDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.journalEntryDetail(id));

    _isLoading = false;

    if (response.success && response.data is Map) {
      _currentEntry = response.data;
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل تفاصيل القيد';
    }

    notifyListeners();
  }

  Future<bool> createJournalEntry(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(ApiEndpoints.journalEntries, body: data);

    _isLoading = false;

    if (response.success) {
      await fetchJournalEntries();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل حفظ قيد اليومية';
      notifyListeners();
      return false;
    }
  }
}
