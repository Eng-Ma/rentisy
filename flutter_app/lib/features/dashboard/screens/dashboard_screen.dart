import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/dashboard_provider.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../vouchers/screens/create_voucher_screen.dart';
import '../../checks/screens/create_check_screen.dart';
import '../../journal_entries/screens/create_journal_entry_screen.dart';
import '../../reports/screens/reports_hub_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboard = context.watch<DashboardProvider>();
    final stats = dashboard.stats;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'لوحة التحكم والمؤشرات المالية',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dashboard.fetchDashboardData(),
            tooltip: 'تحديث البيانات',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboard.isLoading && stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dashboard.fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome & Quick Action Banner
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مرحباً بك في نظام المحاسبة ERP',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'إدارة كاملة للحسابات، المستودعات، الشيكات، والفواتير بمرونة عالية',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Quick Actions Buttons Row
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                                  );
                                },
                                icon: const Icon(Icons.add_shopping_cart, size: 16),
                                label: const Text('فاتورة جديدة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateVoucherScreen()),
                                  );
                                },
                                icon: const Icon(Icons.payments_outlined, size: 16),
                                label: const Text('سند قبض / صرف'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateJournalEntryScreen()),
                                  );
                                },
                                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                                label: const Text('قيد يومية جديد'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateCheckScreen()),
                                  );
                                },
                                icon: const Icon(Icons.fact_check_outlined, size: 16),
                                label: const Text('إضافة شيك للحافظة'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ReportsHubScreen()),
                                  );
                                },
                                icon: const Icon(Icons.analytics_outlined, size: 16),
                                label: const Text('التقارير المالية'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // KPI Stats Grid
                    const Text(
                      'المؤشرات المالية العامة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 600
                                ? 2
                                : 1;

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: constraints.maxWidth > 900 ? 1.6 : 2.0,
                          children: [
                            StatCard(
                              title: 'إجمالي المبيعات',
                              value: Formatters.formatCurrency(stats?['total_sales'] ?? 0),
                              icon: Icons.trending_up_rounded,
                              iconColor: AppColors.primary,
                            ),
                            StatCard(
                              title: 'إجمالي المشتريات',
                              value: Formatters.formatCurrency(stats?['total_purchases'] ?? 0),
                              icon: Icons.shopping_bag_outlined,
                              iconColor: AppColors.purple,
                            ),
                            StatCard(
                              title: 'صافي الأرباح',
                              value: Formatters.formatCurrency(stats?['net_profit'] ?? 0),
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: (stats?['net_profit'] ?? 0) >= 0
                                  ? AppColors.secondary
                                  : AppColors.danger,
                              subtitle: (stats?['net_profit'] ?? 0) >= 0 ? 'أرباح تشغيلية' : 'خسائر تشغيلية',
                            ),
                            StatCard(
                              title: 'شيكات برسم التحصيل',
                              value: Formatters.formatCurrency(stats?['checks_under_collection'] ?? 0),
                              icon: Icons.fact_check_outlined,
                              iconColor: AppColors.accent,
                            ),
                            StatCard(
                              title: 'إجمالي الفواتير',
                              value: Formatters.formatNumber(stats?['total_invoices_count'] ?? 0),
                              icon: Icons.receipt_rounded,
                              iconColor: AppColors.info,
                            ),
                            StatCard(
                              title: 'الأصناف في المستودع',
                              value: Formatters.formatNumber(stats?['total_items'] ?? 0),
                              icon: Icons.inventory_2_outlined,
                              iconColor: AppColors.secondaryDark,
                            ),
                            StatCard(
                              title: 'العملاء والموردين',
                              value: Formatters.formatNumber(stats?['total_parties'] ?? 0),
                              icon: Icons.people_alt_outlined,
                              iconColor: AppColors.primaryDark,
                            ),
                            StatCard(
                              title: 'حركات المناقلات',
                              value: Formatters.formatNumber(stats?['total_transfers_count'] ?? 0),
                              icon: Icons.swap_horiz_rounded,
                              iconColor: AppColors.purple,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Recent Invoices and Vouchers
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recent Invoices
                        Expanded(
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.point_of_sale, size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'أحدث الفواتير المسجلة',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                if (dashboard.recentInvoices.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        'لا توجد فواتير مسجلة بعد',
                                        style: TextStyle(color: AppColors.lightTextSecondary),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: dashboard.recentInvoices.length,
                                    separatorBuilder: (_, __) => const Divider(height: 12),
                                    itemBuilder: (context, idx) {
                                      final inv = dashboard.recentInvoices[idx];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: StatusBadge(status: inv['type'] ?? 'sale'),
                                        title: Text(
                                          inv['party']?['name'] ?? 'طرف عام',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          Formatters.formatDate(inv['date']),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        trailing: Text(
                                          Formatters.formatCurrency(inv['total_amount']),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
