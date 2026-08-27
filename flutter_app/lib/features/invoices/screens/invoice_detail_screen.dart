import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/invoices_provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoicesProvider>().fetchInvoiceDetail(widget.invoiceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoicesProvider = context.watch<InvoicesProvider>();
    final invoice = invoicesProvider.currentInvoice;

    return Scaffold(
      appBar: CustomAppBar(title: 'تفاصيل الفاتورة #${widget.invoiceId}'),
      body: invoicesProvider.isLoading || invoice == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Header Receipt Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'فاتورة #${invoice['id']}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            StatusBadge(status: invoice['type'] ?? 'sale'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRow('تاريخ الفاتورة:', Formatters.formatDate(invoice['date']), isDark),
                        _buildRow('العميل / المورد:', invoice['party']?['name'] ?? 'طرف عام', isDark),
                        _buildRow('المستودع:', invoice['store']?['name'] ?? 'المستودع الرئيسي', isDark),
                        if (invoice['notes'] != null && invoice['notes'].toString().isNotEmpty)
                          _buildRow('ملاحظات:', invoice['notes'], isDark),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'المبلغ الإجمالي:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.formatCurrency(invoice['total_amount']),
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

                  // Line Items Table
                  const Text(
                    'بنود الأصناف والكميات',
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
                        rows: ((invoice['lines'] as List?) ?? []).map((l) {
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
                  const SizedBox(height: 20),

                  // Linked Journal Entry
                  if (invoice['journal_entry'] != null)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تم ترحيل القيد المحاسبي تلقائياً',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'مرجع القيد: ${invoice['journal_entry']['reference']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
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
