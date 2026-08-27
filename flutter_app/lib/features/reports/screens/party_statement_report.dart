import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../parties/providers/parties_provider.dart';
import '../providers/reports_provider.dart';

class PartyStatementReport extends StatefulWidget {
  const PartyStatementReport({super.key});

  @override
  State<PartyStatementReport> createState() => _PartyStatementReportState();
}

class _PartyStatementReportState extends State<PartyStatementReport> {
  int? _selectedPartyId;
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartiesProvider>().fetchParties();
    });
  }

  void _generateReport() {
    if (_selectedPartyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار العميل أو المورد')),
      );
      return;
    }

    context.read<ReportsProvider>().fetchPartyStatement(
      partyId: _selectedPartyId!,
      fromDate: _fromDateController.text.isNotEmpty ? _fromDateController.text : null,
      toDate: _toDateController.text.isNotEmpty ? _toDateController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parties = context.watch<PartiesProvider>().parties;
    final repProvider = context.watch<ReportsProvider>();
    final partyData = repProvider.partyStatement?['report_data'];

    return Scaffold(
      appBar: const CustomAppBar(title: 'كشف حساب عميل / مورد (Party Statement)'),
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
                    value: _selectedPartyId,
                    decoration: const InputDecoration(
                      labelText: 'اختر العميل أو المورد *',
                      prefixIcon: Icon(Icons.person_search_outlined),
                    ),
                    isExpanded: true,
                    items: parties.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text('${p['name']} (${p['type'] == 'customer' ? 'عميل' : 'مورد'})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedPartyId = val);
                      _generateReport();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
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
            else if (partyData != null && partyData['party'] != null) ...[
              // Header Summary Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSumItem('الرصيد الدفتري المستحق', Formatters.formatCurrency(partyData['balance']), AppColors.primary),
                    _buildSumItem('إجمالي مسحوبات / مشتريات الفترة', Formatters.formatCurrency(partyData['total_purchases']), AppColors.purple),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('سجل الفواتير والمعاملات المسجلة للطرف', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if ((partyData['invoices'] as List).isEmpty)
                const EmptyState(title: 'لا توجد فواتير مسجلة لهذا الطرف في هذه الفترة')
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
                          DataColumn(label: Text('رقم الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('نوع الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المستودع', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المبلغ الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: (partyData['invoices'] as List).map((inv) {
                          return DataRow(
                            cells: [
                              DataCell(Text('INV-${inv['id']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(Formatters.formatDate(inv['date']))),
                              DataCell(Text(inv['type'] == 'sale' ? 'مبيعات' : inv['type'] == 'purchase' ? 'مشتريات' : 'مردودات')),
                              DataCell(Text(inv['store']?['name'] ?? 'المستودع الرئيسي')),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(inv['total_amount']),
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
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
