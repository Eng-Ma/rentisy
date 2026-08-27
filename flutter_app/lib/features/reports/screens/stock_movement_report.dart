import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/reports_provider.dart';

class StockMovementReport extends StatefulWidget {
  const StockMovementReport({super.key});

  @override
  State<StockMovementReport> createState() => _StockMovementReportState();
}

class _StockMovementReportState extends State<StockMovementReport> {
  int? _selectedItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
    });
  }

  void _load() {
    if (_selectedItemId == null) return;
    context.read<ReportsProvider>().fetchStockMovementReport(itemId: _selectedItemId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = context.watch<InventoryProvider>().items;
    final repProvider = context.watch<ReportsProvider>();
    final data = repProvider.stockMovementReport;
    final movements = (data?['movements'] as List?) ?? [];
    final selectedItem = data?['selected_item'];

    return Scaffold(
      appBar: const CustomAppBar(title: 'تقرير حركة المخزون والأصناف (Stock Movement)'),
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
                    value: _selectedItemId,
                    decoration: const InputDecoration(
                      labelText: 'اختر الصنف المطلوب متابعة حركته *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    isExpanded: true,
                    items: items.map<DropdownMenuItem<int>>((it) {
                      return DropdownMenuItem<int>(
                        value: it['id'] as int,
                        child: Text('${it['name']} (${it['unit']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedItemId = val);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (repProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (selectedItem != null) ...[
              // Item Profile Card
              GlassCard(
                padding: const EdgeInsets.all(18),
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedItem['name'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'الوحدة: ${selectedItem['unit']} | باركود: ${selectedItem['barcode'] ?? 'لا يوجد'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'سعر البيع: ${Formatters.formatCurrency(selectedItem['sales_price'])}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        Text(
                          'سعر الشراء: ${Formatters.formatCurrency(selectedItem['purchase_price'])}',
                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (movements.isEmpty)
                const EmptyState(title: 'لا توجد حركات بيع أو شراء أو مناقلات مسجلة لهذا الصنف')
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
                          DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المرجع', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المستودع / الطرف', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('وارد (+)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('صادر (-)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: movements.map((m) {
                          final inQty = double.tryParse(m['in_qty'].toString()) ?? 0;
                          final outQty = double.tryParse(m['out_qty'].toString()) ?? 0;

                          return DataRow(
                            cells: [
                              DataCell(Text(Formatters.formatDate(m['date']))),
                              DataCell(Text(m['type'] ?? '')),
                              DataCell(Text(m['reference'] ?? '')),
                              DataCell(Text('${m['party_name']} - ${m['store_name']}')),
                              DataCell(
                                Text(
                                  inQty > 0 ? '+${Formatters.formatNumber(inQty)}' : '-',
                                  style: TextStyle(
                                    fontWeight: inQty > 0 ? FontWeight.bold : FontWeight.normal,
                                    color: inQty > 0 ? AppColors.secondaryDark : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  outQty > 0 ? '-${Formatters.formatNumber(outQty)}' : '-',
                                  style: TextStyle(
                                    fontWeight: outQty > 0 ? FontWeight.bold : FontWeight.normal,
                                    color: outQty > 0 ? AppColors.danger : null,
                                  ),
                                ),
                              ),
                              DataCell(Text(Formatters.formatCurrency(m['unit_price']))),
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
}
