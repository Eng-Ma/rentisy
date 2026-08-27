import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/inventory_provider.dart';

class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController(text: 'قطعة');
  final _purchasePriceController = TextEditingController(text: '0');
  final _salesPriceController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _salesPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      'category_id': _selectedCategoryId,
      'unit': _unitController.text.trim(),
      'purchase_price': double.tryParse(_purchasePriceController.text) ?? 0,
      'sales_price': double.tryParse(_salesPriceController.text) ?? 0,
      'description': _descriptionController.text.trim(),
      'is_active': true,
    };

    final invProvider = context.read<InventoryProvider>();
    final success = await invProvider.createItem(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة الصنف إلى دليل المستودعات بنجاح'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<InventoryProvider>().categories;
    final invProvider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'إضافة صنف جديد'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'اسم الصنف *',
                  hint: 'مثال: شاشة سامسونج 27 بوصة / طابعة ليزرية',
                  prefixIcon: Icons.inventory_2_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال اسم الصنف' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _barcodeController,
                        label: 'الباركود (Barcode)',
                        hint: '628100012345',
                        prefixIcon: Icons.qr_code,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _unitController,
                        label: 'وحدة القياس *',
                        hint: 'قطعة / كرتونة / كغم / متر',
                        prefixIcon: Icons.straighten,
                        validator: (v) => (v == null || v.isEmpty) ? 'الرجاء تحديد الوحدة' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف والمجموعة',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('بدون تصنيف')),
                    ...categories.map<DropdownMenuItem<int?>>((c) {
                      return DropdownMenuItem<int?>(
                        value: c['id'] as int,
                        child: Text(c['name']),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _purchasePriceController,
                        label: 'سعر الشراء (التكلفة) *',
                        hint: '0.00',
                        prefixIcon: Icons.shopping_bag_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _salesPriceController,
                        label: 'سعر البيع *',
                        hint: '0.00',
                        prefixIcon: Icons.sell_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _descriptionController,
                  label: 'وصف ومواصفات الصنف',
                  hint: 'الموديل / اللون / الحجم...',
                  prefixIcon: Icons.notes,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: invProvider.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: invProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ الصنف',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
