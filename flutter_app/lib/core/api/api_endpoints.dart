class ApiEndpoints {
  // Production Cloud URL
  static const String defaultProductionUrl = 'https://codeit-gaza.space/api';
  static const String defaultLocalUrl = 'http://127.0.0.1:8000/api';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8000/api';

  static String baseUrl = defaultProductionUrl;

  // Auth Endpoints
  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get user => '$baseUrl/user';
  static String get logout => '$baseUrl/logout';

  // Dashboard
  static String get dashboard => '$baseUrl/dashboard';

  // Accounts
  static String get accounts => '$baseUrl/accounts';
  static String accountDetail(int id) => '$baseUrl/accounts/$id';
  static String get currencies => '$baseUrl/currencies';

  // Journal Entries
  static String get journalEntries => '$baseUrl/journal-entries';
  static String journalEntryDetail(int id) => '$baseUrl/journal-entries/$id';

  // Cost Centers
  static String get costCenters => '$baseUrl/cost-centers';
  static String costCenterDetail(int id) => '$baseUrl/cost-centers/$id';

  // Vouchers
  static String get vouchers => '$baseUrl/vouchers';
  static String voucherDetail(int id) => '$baseUrl/vouchers/$id';

  // Checks
  static String get checks => '$baseUrl/checks';
  static String checkDetail(int id) => '$baseUrl/checks/$id';
  static String checkStatus(int id) => '$baseUrl/checks/$id/status';

  // Items & Inventory
  static String get items => '$baseUrl/items';
  static String itemDetail(int id) => '$baseUrl/items/$id';
  static String get categories => '$baseUrl/categories';
  static String get stores => '$baseUrl/stores';

  // Stock Transfers
  static String get stockTransfers => '$baseUrl/stock-transfers';
  static String stockTransferDetail(int id) => '$baseUrl/stock-transfers/$id';

  // Parties (Customers & Vendors)
  static String get parties => '$baseUrl/parties';
  static String partyDetail(int id) => '$baseUrl/parties/$id';

  // Invoices
  static String get invoices => '$baseUrl/invoices';
  static String invoiceDetail(int id) => '$baseUrl/invoices/$id';

  // Quotations
  static String get quotations => '$baseUrl/quotations';
  static String quotationDetail(int id) => '$baseUrl/quotations/$id';
  static String convertQuotation(int id) => '$baseUrl/quotations/$id/convert';

  // Fixed Assets
  static String get fixedAssets => '$baseUrl/fixed-assets';
  static String fixedAssetDetail(int id) => '$baseUrl/fixed-assets/$id';
  static String depreciateAsset(int id) => '$baseUrl/fixed-assets/$id/depreciate';

  // Reports
  static String get reportAccountStatement => '$baseUrl/reports/account-statement';
  static String get reportTrialBalance => '$baseUrl/reports/trial-balance';
  static String get reportIncomeStatement => '$baseUrl/reports/income-statement';
  static String get reportPartyStatement => '$baseUrl/reports/party-statement';
  static String get reportAging => '$baseUrl/reports/aging';
  static String get reportCostCenters => '$baseUrl/reports/cost-centers';
  static String get reportChecks => '$baseUrl/reports/checks';
  static String get reportStockMovement => '$baseUrl/reports/stock-movement';

  // AI Direct Database Superpowers
  static String get aiSchema => '$baseUrl/ai/schema';
  static String get aiQuery => '$baseUrl/ai/query';
  static String get aiSearch => '$baseUrl/ai/search';
}
