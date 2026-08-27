import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/reports_provider.dart';

class IncomeStatementReport extends StatefulWidget {
  const IncomeStatementReport({super.key});

  @override
  State<IncomeStatementReport> createState() => _IncomeStatementReportState();
}

class _IncomeStatementReportState extends State<IncomeStatementReport> {
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchIncomeStatement();
    });
  }

  void _generateReport() {
    context.read<ReportsProvider>().fetchIncomeStatement(
      fromDate: _fromDateController.text.isNotEmpty ? _fromDateController.text : null,
      toDate: _toDateController.text.isNotEmpty ? _toDateController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repProvider = context.watch<ReportsProvider>();
    final isData = repProvider.incomeStatement;

    final netIncome = isData != null ? (double.tryParse(isData['net_income'].toString()) ?? 0) : 0.0;
    final isProfit = netIncome >= 0;

    return Scaffold(
      appBar: const CustomAppBar(title: 'قائمة الدخل - الأرباح والخسائر (Income Statement)'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Filter Card
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
            else if (isData != null) ...[
              // Net Profit Big Banner
              GlassCard(
                padding: const EdgeInsets.all(24),
                color: isProfit
                    ? AppColors.secondary.withOpacity(isDark ? 0.2 : 0.1)
                    : AppColors.danger.withOpacity(isDark ? 0.2 : 0.1),
                border: Border.all(
                  color: isProfit ? AppColors.secondary : AppColors.danger,
                  width: 1.5,
                ),
                child: Column(
                  children: [
                    Text(
                      isProfit ? 'صافي أرباح الفترة (Net Profit)' : 'صافي خسائر الفترة (Net Loss)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? AppColors.secondaryDark : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.formatCurrency(netIncome),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isProfit ? AppColors.secondaryDark : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Revenues Section
              const Text('1. الإيرادات التشغيلية والمبيعات (Revenues)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...((isData['revenues'] as List?) ?? []).map((rev) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(rev['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              Formatters.formatCurrency(rev['balance']),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي الإيرادات:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        Text(
                          Formatters.formatCurrency(isData['total_revenue']),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.secondaryDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Expenses Section
              const Text('2. تكلفة المبيعات والمصروفات التشغيلية (Expenses)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...((isData['expenses'] as List?) ?? []).map((exp) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(exp['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              Formatters.formatCurrency(exp['balance']),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المصروفات:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        Text(
                          Formatters.formatCurrency(isData['total_expense']),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
