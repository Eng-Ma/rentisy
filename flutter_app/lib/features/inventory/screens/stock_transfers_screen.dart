import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/inventory_provider.dart';
import 'create_stock_transfer_screen.dart';

class StockTransfersScreen extends StatefulWidget {
  const StockTransfersScreen({super.key});

  @override
  State<StockTransfersScreen> createState() => _StockTransfersScreenState();
}

class _StockTransfersScreenState extends State<StockTransfersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _typeTabs = const [
    {'key': 'all', 'label': 'جميع الحركات'},
    {'key': 'transfer', 'label': 'مناقلة بين مستودعين'},
    {'key': 'stock_in', 'label': 'إدخال مخزني'},
    {'key': 'stock_out', 'label': 'إخراج مخزني'},
    {'key': 'adjustment', 'label': 'تسوية جردية'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _typeTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final key = _typeTabs[_tabController.index]['key']!;
        context.read<InventoryProvider>().fetchStockTransfers(type: key);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchStockTransfers();
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
    final invProvider = context.watch<InventoryProvider>();
    final transfers = invProvider.stockTransfers;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'مناقلات وحركات المخزون (Stock Transfers)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => invProvider.fetchStockTransfers(),
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
            MaterialPageRoute(builder: (_) => const CreateStockTransferScreen()),
          );
        },
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('حركة مخزون جديدة'),
        backgroundColor: AppColors.primary,
      ),
      body: invProvider.isLoading && transfers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : transfers.isEmpty
              ? EmptyState(
                  title: 'لا توجد حركات مناقلات مسجلة',
                  message: 'يمكنك تحويل كميات بين المستودعات أو تسجيل تسوية جردية وإدخال/إخراج مخزني',
                  icon: Icons.swap_horiz_rounded,
                  buttonText: 'إنشاء حركة مخزون',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateStockTransferScreen()),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transfers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = transfers[index];
                    final lines = (t['lines'] as List?) ?? [];
                    final totalQty = lines.fold<double>(
                      0.0,
                      (sum, l) => sum + (double.tryParse(l['quantity']?.toString() ?? '0') ?? 0),
                    );

                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t['transfer_number'] ?? 'TR-${t['id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              StatusBadge(status: t['type'] ?? 'transfer'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${t['from_store']?['name'] ?? 'مستودع'} ➔ ${t['to_store']?['name'] ?? 'مستودع'}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الكمية الإجمالية المنقولة: ${Formatters.formatNumber(totalQty)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                Formatters.formatDate(t['date']),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
