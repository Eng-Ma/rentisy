import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/quotations_provider.dart';

class QuotationDetailScreen extends StatefulWidget {
  final int quotationId;
  const QuotationDetailScreen({super.key, required this.quotationId});

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationsProvider>().fetchQuotationDetail(widget.quotationId);
    });
  }

  Future<void> _handleConvert() async {
    final qProvider = context.read<QuotationsProvider>();
    final success = await qProvider.convertToInvoice(widget.quotationId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحويل عرض السعر إلى فاتورة مبيعات بنجاح وتحديث القيود والمخزون'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qProvider = context.watch<QuotationsProvider>();
    final q = qProvider.currentQuotation;

    return Scaffold(
      appBar: CustomAppBar(title: 'عرض أسعار #${widget.quotationId}'),
      body: qProvider.isLoading || q == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              q['quotation_number'] ?? '',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            StatusBadge(status: q['status'] ?? 'draft'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRow('العميل:', q['party']?['name'] ?? 'عميل عام', isDark),
                        _buildRow('تاريخ العرض:', Formatters.formatDate(q['date']), isDark),
                        if (q['expiry_date'] != null)
                          _buildRow('تاريخ الانتهاء:', Formatters.formatDate(q['expiry_date']), isDark),
                        if (q['notes'] != null && q['notes'].toString().isNotEmpty)
                          _buildRow('ملاحظات:', q['notes'], isDark),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المبلغ الإجمالي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              Formatters.formatCurrency(q['total_amount']),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lines Table
                  const Text(
                    'بنود الأصناف والأسعار',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? AppColors.darkSurface : AppColors.lightDivider,
                        ),
                        columns: const [
                          DataColumn(label: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: ((q['lines'] as List?) ?? []).map((l) {
                          return DataRow(
                            cells: [
                              DataCell(Text(l['item']?['name'] ?? 'صنف', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('${l['quantity']}')),
                              DataCell(Text(Formatters.formatCurrency(l['unit_price']))),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(l['total_price']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1-Click Convert Button (If not yet converted)
                  if (q['status'] != 'converted')
                    ElevatedButton.icon(
                      onPressed: qProvider.isLoading ? null : _handleConvert,
                      icon: const Icon(Icons.transform_rounded),
                      label: const Text(
                        'تحويل إلى فاتورة مبيعات الآن (1-Click Convert)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'تم تحويل عرض السعر هذا مسبقاً إلى فاتورة مبيعات',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
