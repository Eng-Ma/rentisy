import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/reports_provider.dart';

class AgingReport extends StatefulWidget {
  const AgingReport({super.key});

  @override
  State<AgingReport> createState() => _AgingReportState();
}

class _AgingReportState extends State<AgingReport> {
  String _type = 'customer'; // customer or vendor

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchAgingReport(type: _type);
    });
  }

  void _onTypeChanged(String type) {
    setState(() => _type = type);
    context.read<ReportsProvider>().fetchAgingReport(type: type);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repProvider = context.watch<ReportsProvider>();
    final agingData = repProvider.agingReport;
    final list = agingData?['aging_data'] as List? ?? [];
    final totals = agingData?['totals'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'تقرير أعمار الديون (Debt Aging Report)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ReportsProvider>().fetchAgingReport(type: _type),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Selector
            GlassCard(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('ديون العملاء (Receivables)')),
                      selected: _type == 'customer',
                      onSelected: (_) => _onTypeChanged('customer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('مستحقات الموردين (Payables)')),
                      selected: _type == 'vendor',
                      onSelected: (_) => _onTypeChanged('vendor'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (repProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (totals != null) ...[
              // Aging Periods Totals Grid
              GlassCard(
                padding: const EdgeInsets.all(18),
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPeriod('0-30 يوم', Formatters.formatCurrency(totals['period_0_30']), AppColors.secondaryDark),
                        _buildPeriod('31-60 يوم', Formatters.formatCurrency(totals['period_31_60']), AppColors.info),
                        _buildPeriod('61-90 يوم', Formatters.formatCurrency(totals['period_61_90']), AppColors.accent),
                        _buildPeriod('+90 يوم (متعثر)', Formatters.formatCurrency(totals['period_over_90']), AppColors.danger),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي الديون المعلقة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          Formatters.formatCurrency(totals['total']),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (list.isEmpty)
                const EmptyState(title: 'لا توجد ديون معلقة مسجلة')
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
                          DataColumn(label: Text('الطرف', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('0-30 يوم', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('31-60 يوم', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('61-90 يوم', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('+90 يوم', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: list.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(Formatters.formatCurrency(p['period_0_30']))),
                              DataCell(Text(Formatters.formatCurrency(p['period_31_60']))),
                              DataCell(Text(Formatters.formatCurrency(p['period_61_90']))),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(p['period_over_90']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (double.tryParse(p['period_over_90'].toString()) ?? 0) > 0 ? AppColors.danger : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(p['total']),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
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

  Widget _buildPeriod(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
