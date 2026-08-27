import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/cost_centers_provider.dart';

class CostCentersScreen extends StatefulWidget {
  const CostCentersScreen({super.key});

  @override
  State<CostCentersScreen> createState() => _CostCentersScreenState();
}

class _CostCentersScreenState extends State<CostCentersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CostCentersProvider>().fetchCostCenters();
    });
  }

  void _showAddCostCenterDialog([dynamic parentCenter]) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.donut_large_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(parentCenter != null ? 'إضافة مركز تكلفة فرعي' : 'إضافة مركز تكلفة رئيسي'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (parentCenter != null) ...[
                Text(
                  'تابع للمركز الرئيسي: ${parentCenter['name']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],
              CustomTextField(
                controller: codeController,
                label: 'كود مركز التكلفة *',
                hint: 'CC-01',
                validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال الكود' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: nameController,
                label: 'اسم مركز التكلفة *',
                hint: 'مشروع برج الرياض / قسم التسويق',
                validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال الاسم' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: descController,
                label: 'الوصف',
                hint: 'تفاصيل المشروع أو القسم...',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await context.read<CostCentersProvider>().createCostCenter({
                'code': codeController.text.trim(),
                'name': nameController.text.trim(),
                'parent_id': parentCenter?['id'],
                'description': descController.text.trim(),
                'is_active': true,
              });

              if (mounted) Navigator.pop(ctx);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إنشاء مركز التكلفة بنجاح'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ccProvider = context.watch<CostCentersProvider>();
    final costCenters = ccProvider.costCenters;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'مراكز التكلفة والمشاريع (Cost Centers)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ccProvider.fetchCostCenters(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCostCenterDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة مركز تكلفة'),
        backgroundColor: AppColors.primary,
      ),
      body: ccProvider.isLoading && costCenters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : costCenters.isEmpty
              ? EmptyState(
                  title: 'لا توجد مراكز تكلفة معرفة',
                  message: 'تساعدك مراكز التكلفة في متابعة إيرادات ومصروفات كل مشروع أو قسم بدقة',
                  icon: Icons.donut_large_outlined,
                  buttonText: 'إضافة مركز تكلفة',
                  onButtonPressed: () => _showAddCostCenterDialog(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: costCenters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cc = costCenters[index];

                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.donut_large_rounded, color: AppColors.primary, size: 22),
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
                                      cc['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cc['code'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (cc['parent'] != null)
                                  Text(
                                    'المركز الأب: ${cc['parent']['name']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                if (cc['description'] != null && cc['description'].toString().isNotEmpty)
                                  Text(
                                    cc['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            tooltip: 'إضافة مركز فرعي',
                            onPressed: () => _showAddCostCenterDialog(cc),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
