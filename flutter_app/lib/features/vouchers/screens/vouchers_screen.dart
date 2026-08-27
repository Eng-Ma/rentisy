import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/vouchers_provider.dart';
import 'create_voucher_screen.dart';
import 'voucher_detail_screen.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final types = ['all', 'receipt', 'payment'];
        context.read<VouchersProvider>().setSelectedType(types[_tabController.index]);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VouchersProvider>().fetchVouchers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vouchersProvider = context.watch<VouchersProvider>();
    final vouchers = vouchersProvider.vouchers;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'سندات القبض والصرف (Vouchers)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => vouchersProvider.fetchVouchers(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'جميع السندات'),
            Tab(text: 'سندات القبض (Receipts)'),
            Tab(text: 'سندات الصرف (Payments)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateVoucherScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('سند جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: vouchersProvider.isLoading && vouchers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : vouchers.isEmpty
              ? EmptyState(
                  title: 'لا توجد سندات مسجلة',
                  message: 'يمكنك إنشاء سند قبض نقد/شيك أو سند صرف وتوليد القيد تلقائياً',
                  icon: Icons.payments_outlined,
                  buttonText: 'إنشاء سند جديد',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateVoucherScreen()),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vouchers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    final isReceipt = voucher['type'] == 'receipt';

                    return GlassCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoucherDetailScreen(voucherId: voucher['id']),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isReceipt
                                  ? AppColors.secondary.withOpacity(0.12)
                                  : AppColors.danger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isReceipt ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isReceipt ? AppColors.secondaryDark : AppColors.danger,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      voucher['voucher_number'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(voucher['amount']),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: isReceipt ? AppColors.secondaryDark : AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  voucher['party']?['name'] ?? voucher['target_account']?['name'] ?? 'طرف عام',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    StatusBadge(status: voucher['type'] ?? 'receipt'),
                                    const SizedBox(width: 8),
                                    Text(
                                      'طريقة الدفع: ${voucher['payment_method'] == 'cash' ? 'نقداً' : voucher['payment_method'] == 'bank' ? 'حوالة بنكية' : 'شيك'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      Formatters.formatDate(voucher['date']),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
