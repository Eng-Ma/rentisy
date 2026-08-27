import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/reports_provider.dart';

class AccountStatementReport extends StatefulWidget {
  const AccountStatementReport({super.key});

  @override
  State<AccountStatementReport> createState() => _AccountStatementReportState();
}

class _AccountStatementReportState extends State<AccountStatementReport> {
  int? _selectedAccountId;
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().fetchAccounts();
    });
  }

  void _generateReport() {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الحساب المالي أولاً')),
      );
      return;
    }

    context.read<ReportsProvider>().fetchAccountStatement(
      accountId: _selectedAccountId!,
      fromDate: _fromDateController.text.isNotEmpty ? _fromDateController.text : null,
      toDate: _toDateController.text.isNotEmpty ? _toDateController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = context.watch<AccountsProvider>().accounts;
    final repProvider = context.watch<ReportsProvider>();
    final statementData = repProvider.accountStatement;

    return Scaffold(
      appBar: const CustomAppBar(title: 'كشف حساب تفصيلي (Account Statement)'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Controls Card
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'اختر الحساب المالي *',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    isExpanded: true,
                    items: accounts.map<DropdownMenuItem<int>>((a) {
                      return DropdownMenuItem<int>(
                        value: a['id'] as int,
                        child: Text('${a['code']} - ${a['name']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedAccountId = val);
                      _generateReport();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromDateController,
                          decoration: const InputDecoration(
                            labelText: 'من تاريخ',
                            prefixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2025, 1, 1),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              _fromDateController.text = picked.toString().substring(0, 10);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _toDateController,
                          decoration: const InputDecoration(
                            labelText: 'إلى تاريخ',
                            prefixIcon: Icon(Icons.event, size: 18),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              _toDateController.text = picked.toString().substring(0, 10);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _generateReport,
                    icon: const Icon(Icons.search),
                    label: const Text('عرض كشف الحساب'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (repProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (statementData != null) ...[
              // Summary Banner
              GlassCard(
                padding: const EdgeInsets.all(18),
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSumItem('إجمالي المدين', Formatters.formatCurrency(statementData['total_debit']), AppColors.primary),
                    _buildSumItem('إجمالي الدائن', Formatters.formatCurrency(statementData['total_credit']), AppColors.purple),
                    _buildSumItem('الرصيد النهائي', Formatters.formatCurrency(statementData['final_balance']), AppColors.secondaryDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Table of Lines
              if ((statementData['statement'] as List).isEmpty)
                const EmptyState(title: 'لا توجد حركات مسجلة على هذا الحساب في هذه الفترة')
              else
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? AppColors.darkSurface : AppColors.lightDivider,
                        ),
                        columns: const [
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المرجع', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('البيان', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('مدين', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('دائن', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الرصيد المتحرك', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: (statementData['statement'] as List).map((l) {
                          return DataRow(
                            cells: [
                              DataCell(Text(Formatters.formatDate(l['date']))),
                              DataCell(Text(l['reference'] ?? '-')),
                              DataCell(Text(l['description'] ?? '-')),
                              DataCell(Text(Formatters.formatCurrency(l['debit']))),
                              DataCell(Text(Formatters.formatCurrency(l['credit']))),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(l['balance']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSumItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
