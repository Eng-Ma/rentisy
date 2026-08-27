import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/inventory_provider.dart';
import 'create_item_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
      context.read<InventoryProvider>().fetchCategories();
      context.read<InventoryProvider>().fetchStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invProvider = context.watch<InventoryProvider>();
    final items = invProvider.items;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'دليل الأصناف والمستودعات (Items & Catalog)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => invProvider.fetchItems(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateItemScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة صنف جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث باسم الصنف أو الباركود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => invProvider.fetchItems(search: _searchController.text),
                ),
              ),
              onSubmitted: (val) => invProvider.fetchItems(search: val),
            ),
          ),
          Expanded(
            child: invProvider.isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? EmptyState(
                        title: 'لا توجد أصناف في الدليل',
                        message: 'يمكنك تعريف أصناف المخزون مع سعر الشراء وسعر البيع والوحدة',
                        icon: Icons.inventory_2_outlined,
                        buttonText: 'إضافة صنف جديد',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateItemScreen()),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final stockItems = (item['store_items'] as List?) ?? [];
                          final totalQty = stockItems.fold<double>(
                            0.0,
                            (sum, s) => sum + (double.tryParse(s['quantity']?.toString() ?? '0') ?? 0),
                          );

                          return GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 24),
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
                                            item['name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: totalQty > 0
                                                  ? AppColors.secondary.withOpacity(0.15)
                                                  : AppColors.danger.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'الرصيد: ${Formatters.formatNumber(totalQty)} ${item['unit'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: totalQty > 0
                                                    ? AppColors.secondaryDark
                                                    : AppColors.danger,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (item['barcode'] != null && item['barcode'].toString().isNotEmpty) ...[
                                            Text(
                                              'باركود: ${item['barcode']}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          if (item['category'] != null)
                                            Text(
                                              'تصنيف: ${item['category']['name']}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'سعر البيع: ${Formatters.formatCurrency(item['sales_price'])}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Text(
                                            'سعر الشراء (التكلفة): ${Formatters.formatCurrency(item['purchase_price'])}',
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
