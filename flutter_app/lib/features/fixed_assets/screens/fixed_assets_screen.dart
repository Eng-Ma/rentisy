import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/fixed_assets_provider.dart';
import 'create_asset_screen.dart';

class FixedAssetsScreen extends StatefulWidget {
  const FixedAssetsScreen({super.key});

  @override
  State<FixedAssetsScreen> createState() => _FixedAssetsScreenState();
}

class _FixedAssetsScreenState extends State<FixedAssetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FixedAssetsProvider>().fetchFixedAssets();
    });
  }

  void _showDepreciateDialog(dynamic asset) {
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final amountController = TextEditingController();

    // Default calculated yearly depreciation
    final cost = double.tryParse(asset['purchase_cost'].toString()) ?? 0;
    final salvage = double.tryParse((asset['salvage_value'] ?? 0).toString()) ?? 0;
    final rate = double.tryParse((asset['depreciation_rate'] ?? 20).toString()) ?? 20;
    final defaultDepr = ((cost - salvage) * (rate / 100)).clamp(0.0, double.infinity);
    amountController.text = defaultDepr.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.trending_down, color: AppColors.accent),
            SizedBox(width: 8),
            Text('احتساب وترحيل قسط الإهلاك'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أصل ثابت: ${asset['name']} (${asset['code']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'القيمة الدفترية الحالية: ${Formatters.formatCurrency(asset['current_book_value'])}',
              style: const TextStyle(fontSize: 13, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'تاريخ الإهلاك *',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  dateController.text = picked.toString().substring(0, 10);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'مبلغ قسط الإهلاك *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;

              final success = await context.read<FixedAssetsProvider>().depreciateAsset(
                asset['id'],
                {
                  'date': dateController.text,
                  'amount': amount,
                },
              );

              if (mounted) Navigator.pop(ctx);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم احتساب الإهلاك وتوليد القيد المحاسبي بنجاح'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('تأكيد وترحيل القيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetsProvider = context.watch<FixedAssetsProvider>();
    final assets = assetsProvider.assets;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'سجل الأصول الثابتة والإهلاك (Fixed Assets)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => assetsProvider.fetchFixedAssets(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAssetScreen()),
          );
        },
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('تسجيل أصل ثابت جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: assetsProvider.isLoading && assets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : assets.isEmpty
              ? EmptyState(
                  title: 'لا توجد أصول ثابتة مسجلة',
                  message: 'يمكنك تسجيل أصول المنشأة واحتساب الإهلاك وتوليد قيود مجمع الإهلاك آلياً',
                  icon: Icons.business_center_outlined,
                  buttonText: 'تسجيل أصل جديد',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateAssetScreen()),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: assets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final asset = assets[index];

                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      asset['code'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    asset['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showDepreciateDialog(asset),
                                icon: const Icon(Icons.trending_down, size: 14),
                                label: const Text('إهلاك الأصل'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetric('تكلفة الشراء', Formatters.formatCurrency(asset['purchase_cost']), isDark),
                              _buildMetric('مجمع الإهلاك', Formatters.formatCurrency(asset['total_depreciated']), isDark),
                              _buildMetric('القيمة الدفترية', Formatters.formatCurrency(asset['current_book_value']), isDark, isHighlight: true),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'تاريخ الشراء: ${Formatters.formatDate(asset['purchase_date'])}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                'نسبة الإهلاك: ${asset['depreciation_rate']}% سنوي',
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

  Widget _buildMetric(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isHighlight ? AppColors.secondaryDark : null,
          ),
        ),
      ],
    );
  }
}
