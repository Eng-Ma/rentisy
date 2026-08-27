import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/reports_provider.dart';

class TrialBalanceReport extends StatefulWidget {
  const TrialBalanceReport({super.key});

  @override
  State<TrialBalanceReport> createState() => _TrialBalanceReportState();
}

class _TrialBalanceReportState extends State<TrialBalanceReport> {
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchTrialBalance();
    });
  }

  void _generateReport() {
    context.read<ReportsProvider>().fetchTrialBalance(
      fromDate: _fromDateController.text.isNotEmpty ? _fromDateController.text : null,
      toDate: _toDateController.text.isNotEmpty ? _toDateController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repProvider = context.watch<ReportsProvider>();
    final tbData = repProvider.trialBalance;

    final sumDebit = tbData != null ? (double.tryParse(tbData['sum_debit'].toString()) ?? 0) : 0.0;
    final sumCredit = tbData != null ? (double.tryParse(tbData['sum_credit'].toString()) ?? 0) : 0.0;
    final isBalanced = (sumDebit - sumCredit).abs() < 0.01;

    return Scaffold(
      appBar: const CustomAppBar(title: 'ميزان المراجعة (Trial Balance)'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromDateController,
                      decoration: const InputDecoration(labelText: 'من تاريخ', prefixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2025, 1, 1),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) _fromDateController.text = picked.toString().substring(0, 10);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _toDateController,
                      decoration: const InputDecoration(labelText: 'إلى تاريخ', prefixIcon: Icon(Icons.event)),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) _toDateController.text = picked.toString().substring(0, 10);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _generateReport,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    child: const Text('تحديث'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (repProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (tbData != null) ...[
              // Totals Balance Status
              GlassCard(
                padding: const EdgeInsets.all(18),
                color: isBalanced
                    ? AppColors.secondary.withOpacity(isDark ? 0.15 : 0.08)
                    : AppColors.danger.withOpacity(isDark ? 0.15 : 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSumItem('مجموع الأرصدة المدينة', Formatters.formatCurrency(sumDebit), AppColors.primary),
                    _buildSumItem('مجموع الأرصدة الدائنة', Formatters.formatCurrency(sumCredit), AppColors.purple),
                    _buildSumItem(
                      'حالة التوازن',
                      isBalanced ? 'متوازن ✓' : 'غير متوازن ✗',
                      isBalanced ? AppColors.secondaryDark : AppColors.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if ((tbData['trial_balance'] as List).isEmpty)
                const EmptyState(title: 'لا توجد حركات أو أرصدة في هذه الفترة')
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
                          DataColumn(label: Text('كود الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('اسم الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('مجموع المدين', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('مجموع الدائن', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('رصيد مدين', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('رصيد دائن', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: (tbData['trial_balance'] as List).map((acc) {
                          final isDebitBalance = acc['balance_type'] == 'debit';

                          return DataRow(
                            cells: [
                              DataCell(Text(acc['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(acc['name'] ?? '')),
                              DataCell(Text(Formatters.formatCurrency(acc['total_debit']))),
                              DataCell(Text(Formatters.formatCurrency(acc['total_credit']))),
                              DataCell(
                                Text(
                                  isDebitBalance ? Formatters.formatCurrency(acc['balance']) : '-',
                                  style: TextStyle(
                                    fontWeight: isDebitBalance ? FontWeight.bold : FontWeight.normal,
                                    color: isDebitBalance ? AppColors.primary : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  !isDebitBalance ? Formatters.formatCurrency(acc['balance']) : '-',
                                  style: TextStyle(
                                    fontWeight: !isDebitBalance ? FontWeight.bold : FontWeight.normal,
                                    color: !isDebitBalance ? AppColors.purple : null,
                                  ),
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
