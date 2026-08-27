import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../cost_centers/providers/cost_centers_provider.dart';
import '../providers/reports_provider.dart';

class CostCentersReport extends StatefulWidget {
  const CostCentersReport({super.key});

  @override
  State<CostCentersReport> createState() => _CostCentersReportState();
}

class _CostCentersReportState extends State<CostCentersReport> {
  int? _selectedCostCenterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CostCentersProvider>().fetchCostCenters();
    });
  }

  void _generate() {
    if (_selectedCostCenterId == null) return;
    context.read<ReportsProvider>().fetchCostCentersReport(costCenterId: _selectedCostCenterId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final costCenters = context.watch<CostCentersProvider>().costCenters;
    final repProvider = context.watch<ReportsProvider>();
    final ccData = repProvider.costCentersReport;

    return Scaffold(
      appBar: const CustomAppBar(title: 'كشف مراكز التكلفة (Cost Centers Report)'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedCostCenterId,
                    decoration: const InputDecoration(
                      labelText: 'اختر مركز التكلفة / المشروع *',
                      prefixIcon: Icon(Icons.donut_large_outlined),
                    ),
                    isExpanded: true,
                    items: costCenters.map<DropdownMenuItem<int>>((cc) {
                      return DropdownMenuItem<int>(
                        value: cc['id'] as int,
                        child: Text('${cc['code']} - ${cc['name']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCostCenterId = val);
                      _generate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (repProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (ccData != null && ccData['report_data'] != null) ...[
              GlassCard(
                padding: const EdgeInsets.all(18),
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSum('إجمالي المدين (المصروفات)', Formatters.formatCurrency(ccData['total_debit']), AppColors.danger),
                    _buildSum('إجمالي الدائن (الإيرادات)', Formatters.formatCurrency(ccData['total_credit']), AppColors.secondaryDark),
                    _buildSum('صافي التكلفة', Formatters.formatCurrency(ccData['net_balance']), AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if ((ccData['report_data'] as List).isEmpty)
                const EmptyState(title: 'لا توجد حركات مالية مسندة لمركز التكلفة هذا')
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
                          DataColumn(label: Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('البيان', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('مدين', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('دائن', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: (ccData['report_data'] as List).map((l) {
                          return DataRow(
                            cells: [
                              DataCell(Text(Formatters.formatDate(l['date']))),
                              DataCell(Text(l['reference'] ?? '-')),
                              DataCell(Text(l['account_name'] ?? '-')),
                              DataCell(Text(l['description'] ?? '-')),
                              DataCell(Text(Formatters.formatCurrency(l['debit']))),
                              DataCell(Text(Formatters.formatCurrency(l['credit']))),
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

  Widget _buildSum(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
