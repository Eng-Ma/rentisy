import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _stats;
  List<dynamic> _recentInvoices = [];
  List<dynamic> _recentVouchers = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get recentInvoices => _recentInvoices;
  List<dynamic> get recentVouchers => _recentVouchers;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.dashboard);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _stats = response.rawJson['stats'];
      _recentInvoices = response.rawJson['recent_invoices'] ?? [];
      _recentVouchers = response.rawJson['recent_vouchers'] ?? [];
    } else {
      _errorMessage = response.message ?? 'تعذر تحميل بيانات لوحة التحكم';
    }

    notifyListeners();
  }
}
