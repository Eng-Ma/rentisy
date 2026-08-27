import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/vouchers_provider.dart';

class VoucherDetailScreen extends StatefulWidget {
  final int voucherId;
  const VoucherDetailScreen({super.key, required this.voucherId});

  @override
  State<VoucherDetailScreen> createState() => _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends State<VoucherDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VouchersProvider>().fetchVoucherDetail(widget.voucherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vouchersProvider = context.watch<VouchersProvider>();
    final voucher = vouchersProvider.currentVoucher;

    return Scaffold(
      appBar: CustomAppBar(title: 'تفاصيل السند #${widget.voucherId}'),
      body: vouchersProvider.isLoading || voucher == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              voucher['voucher_number'] ?? '',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            StatusBadge(status: voucher['type'] ?? 'receipt'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Formatters.formatCurrency(voucher['amount']),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: voucher['type'] == 'receipt'
                                ? AppColors.secondaryDark
                                : AppColors.danger,
                          ),
                        ),
                        const Divider(height: 24),

                        // Info rows
                        _buildInfoRow('التاريخ', Formatters.formatDate(voucher['date']), isDark),
                        _buildInfoRow('طريقة الدفع', voucher['payment_method'] == 'cash' ? 'نقداً' : voucher['payment_method'] == 'bank' ? 'بنكي' : 'شيك', isDark),
                        _buildInfoRow('الحساب المالي (الخزينة)', voucher['account']?['name'] ?? '-', isDark),
                        _buildInfoRow('الطرف المقابل', voucher['party']?['name'] ?? voucher['target_account']?['name'] ?? '-', isDark),
                        if (voucher['cost_center'] != null)
                          _buildInfoRow('مركز التكلفة', voucher['cost_center']['name'], isDark),
                        if (voucher['notes'] != null && voucher['notes'].toString().isNotEmpty)
                          _buildInfoRow('البيان / ملاحظات', voucher['notes'], isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Journal Entry Reference Box
                  if (voucher['journal_entry'] != null) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.link, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'القيد المحاسبي المرحل آلياً',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'المرجع: ${voucher['journal_entry']['reference']} | البيان: ${voucher['journal_entry']['description']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
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

  Widget _buildInfoRow(String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
