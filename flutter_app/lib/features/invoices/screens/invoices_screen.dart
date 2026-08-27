import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/invoices_provider.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final _typeTabs = const [
    {'key': 'all', 'label': 'جميع الفواتير'},
    {'key': 'sale', 'label': 'المبيعات'},
    {'key': 'purchase', 'label': 'المشتريات'},
    {'key': 'sale_return', 'label': 'مردود مبيعات'},
    {'key': 'purchase_return', 'label': 'مردود مشتريات'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _typeTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final key = _typeTabs[_tabController.index]['key']!;
        context.read<InvoicesProvider>().setType(key);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoicesProvider>().fetchInvoices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoicesProvider = context.watch<InvoicesProvider>();
    final invoices = invoicesProvider.invoices;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'إدارة الفواتير والمبيعات (Invoices)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => invoicesProvider.fetchInvoices(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: _typeTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('فاتورة جديدة'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث برقم الفاتورة أو اسم العميل / المورد...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => invoicesProvider.fetchInvoices(search: _searchController.text),
                ),
              ),
              onSubmitted: (val) => invoicesProvider.fetchInvoices(search: val),
            ),
          ),
          Expanded(
            child: invoicesProvider.isLoading && invoices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : invoices.isEmpty
                    ? EmptyState(
                        title: 'لا توجد فواتير مسجلة',
                        message: 'يمكنك إنشاء فاتورة مبيعات أو مشتريات وتحديث المخزون والقيود آلياً',
                        icon: Icons.point_of_sale_outlined,
                        buttonText: 'إنشاء فاتورة جديدة',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final inv = invoices[index];
                          final isSale = inv['type'] == 'sale';

                          return GlassCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvoiceDetailScreen(invoiceId: inv['id']),
                                ),
                              );
                            },
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSale
                                        ? AppColors.primary.withOpacity(0.12)
                                        : AppColors.purple.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isSale ? Icons.shopping_bag_outlined : Icons.inventory_outlined,
                                    color: isSale ? AppColors.primary : AppColors.purple,
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
                                            'فاتورة #${inv['id']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            Formatters.formatCurrency(inv['total_amount']),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        inv['party']?['name'] ?? 'طرف عام',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          StatusBadge(status: inv['type'] ?? 'sale'),
                                          const SizedBox(width: 8),
                                          Text(
                                            'مستودع: ${inv['store']?['name'] ?? 'الرئيسي'}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            Formatters.formatDate(inv['date']),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
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
          ),
        ],
      ),
    );
  }
}
