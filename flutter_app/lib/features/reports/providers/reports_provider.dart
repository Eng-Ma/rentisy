import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class ReportsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Report results
  Map<String, dynamic>? _accountStatement;
  Map<String, dynamic>? _trialBalance;
  Map<String, dynamic>? _incomeStatement;
  Map<String, dynamic>? _partyStatement;
  Map<String, dynamic>? _agingReport;
  Map<String, dynamic>? _costCentersReport;
  Map<String, dynamic>? _checksReport;
  Map<String, dynamic>? _stockMovementReport;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get accountStatement => _accountStatement;
  Map<String, dynamic>? get trialBalance => _trialBalance;
  Map<String, dynamic>? get incomeStatement => _incomeStatement;
  Map<String, dynamic>? get partyStatement => _partyStatement;
  Map<String, dynamic>? get agingReport => _agingReport;
  Map<String, dynamic>? get costCentersReport => _costCentersReport;
  Map<String, dynamic>? get checksReport => _checksReport;
  Map<String, dynamic>? get stockMovementReport => _stockMovementReport;

  Future<void> fetchAccountStatement({required int accountId, String? fromDate, String? toDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{'account_id': accountId};
    if (fromDate != null && fromDate.isNotEmpty) query['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) query['to_date'] = toDate;

    final response = await ApiService.get(ApiEndpoints.reportAccountStatement, queryParams: query);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _accountStatement = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج كشف الحساب';
    }

    notifyListeners();
  }

  Future<void> fetchTrialBalance({String? fromDate, String? toDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (fromDate != null && fromDate.isNotEmpty) query['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) query['to_date'] = toDate;

    final response = await ApiService.get(ApiEndpoints.reportTrialBalance, queryParams: query);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _trialBalance = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج ميزان المراجعة';
    }

    notifyListeners();
  }

  Future<void> fetchIncomeStatement({String? fromDate, String? toDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (fromDate != null && fromDate.isNotEmpty) query['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) query['to_date'] = toDate;

    final response = await ApiService.get(ApiEndpoints.reportIncomeStatement, queryParams: query);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _incomeStatement = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج قائمة الدخل';
    }

    notifyListeners();
  }

  Future<void> fetchPartyStatement({required int partyId, String? fromDate, String? toDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{'party_id': partyId};
    if (fromDate != null && fromDate.isNotEmpty) query['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) query['to_date'] = toDate;

    final response = await ApiService.get(ApiEndpoints.reportPartyStatement, queryParams: query);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _partyStatement = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج كشف حساب الطرف';
    }

    notifyListeners();
  }

  Future<void> fetchAgingReport({String type = 'customer'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.reportAging, queryParams: {'type': type});

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _agingReport = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج تقرير أعمار الديون';
    }

    notifyListeners();
  }

  Future<void> fetchCostCentersReport({int? costCenterId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (costCenterId != null) query['cost_center_id'] = costCenterId;

    final response = await ApiService.get(ApiEndpoints.reportCostCenters, queryParams: query);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _costCentersReport = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج كشف مراكز التكلفة';
    }

    notifyListeners();
  }

  Future<void> fetchChecksReport({String? type, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (type != null && type != 'all') query['type'] = type;
    if (status != null && status != 'all') query['status'] = status;

    final response = await ApiService.get(ApiEndpoints.reportChecks, queryParams: query);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _checksReport = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج تقرير الشيكات';
    }

    notifyListeners();
  }

  Future<void> fetchStockMovementReport({int? itemId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (itemId != null) query['item_id'] = itemId;

    final response = await ApiService.get(ApiEndpoints.reportStockMovement, queryParams: query);

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      _stockMovementReport = response.rawJson as Map<String, dynamic>;
    } else {
      _errorMessage = response.message ?? 'تعذر استخراج تقرير حركة المخزون';
    }

    notifyListeners();
  }
}
