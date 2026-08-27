import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/inventory_provider.dart';

class CreateStockTransferScreen extends StatefulWidget {
  const CreateStockTransferScreen({super.key});

  @override
  State<CreateStockTransferScreen> createState() => _CreateStockTransferScreenState();
}

class _TransferLineInput {
  int? itemId;
  final qtyController = TextEditingController(text: '1');
  final costController = TextEditingController(text: '0');

  double get quantity => double.tryParse(qtyController.text) ?? 1.0;
  double get unitCost => double.tryParse(costController.text) ?? 0.0;

  void dispose() {
    qtyController.dispose();
    costController.dispose();
  }
}

class _CreateStockTransferScreenState extends State<CreateStockTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final _notesController = TextEditingController();

  String _type = 'transfer'; // transfer, stock_in, stock_out, adjustment
  int? _fromStoreId;
  int? _toStoreId;

  final List<_TransferLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    _addLine();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
      context.read<InventoryProvider>().fetchStores();
    });
  }

  void _addLine() {
    setState(() {
      _lines.add(_TransferLineInput());
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    for (var l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == 'transfer' && _fromStoreId == _toStoreId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن أن يكون المستودع المحول منه وإليه نفس المستودع')),
      );
      return;
    }

    for (var l in _lines) {
      if (l.itemId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد الصنف لجميع بنود الحركة')),
        );
        return;
      }
    }

    final data = {
      'type': _type,
      'date': _dateController.text,
      'from_store_id': _fromStoreId,
      'to_store_id': _toStoreId,
      'notes': _notesController.text,
      'lines': _lines.map((l) {
        return {
          'item_id': l.itemId,
          'quantity': l.quantity,
          'unit_cost': l.unitCost,
        };
      }).toList(),
    };

    final invProvider = context.read<InventoryProvider>();
    final success = await invProvider.createStockTransfer(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ حركة المخزون وتحديث الأرصدة بنجاح'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<InventoryProvider>().items;
    final stores = context.watch<InventoryProvider>().stores;
    final invProvider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'تسجيل حركة مخزون / مناقلة'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              GlassCard(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('مناقلة مستودعية'),
                      selected: _type == 'transfer',
                      onSelected: (_) => setState(() => _type = 'transfer'),
                    ),
                    ChoiceChip(
                      label: const Text('إدخال مخزني'),
                      selected: _type == 'stock_in',
                      onSelected: (_) => setState(() => _type = 'stock_in'),
                    ),
                    ChoiceChip(
                      label: const Text('إخراج مخزني'),
                      selected: _type == 'stock_out',
                      onSelected: (_) => setState(() => _type = 'stock_out'),
                    ),
                    ChoiceChip(
                      label: const Text('تسوية جردية'),
                      selected: _type == 'adjustment',
                      onSelected: (_) => setState(() => _type = 'adjustment'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warehouse Selectors
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _dateController,
                      label: 'تاريخ الحركة *',
                      prefixIcon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          _dateController.text = picked.toString().substring(0, 10);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_type == 'transfer' || _type == 'stock_out') ...[
                      DropdownButtonFormField<int>(
                        value: _fromStoreId,
                        decoration: const InputDecoration(
                          labelText: 'المستودع المصدر (المحول منه) *',
                          prefixIcon: Icon(Icons.output_rounded),
                        ),
                        isExpanded: true,
                        items: stores.map<DropdownMenuItem<int>>((s) {
                          return DropdownMenuItem<int>(
                            value: s['id'] as int,
                            child: Text(s['name']),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _fromStoreId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_type == 'transfer' || _type == 'stock_in') ...[
                      DropdownButtonFormField<int>(
                        value: _toStoreId,
                        decoration: const InputDecoration(
                          labelText: 'المستودع الهدف (المحول إليه) *',
                          prefixIcon: Icon(Icons.input_rounded),
                        ),
                        isExpanded: true,
                        items: stores.map<DropdownMenuItem<int>>((s) {
                          return DropdownMenuItem<int>(
                            value: s['id'] as int,
                            child: Text(s['name']),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _toStoreId = val),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lines Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الأصناف والكميات المنقولة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('إضافة صنف'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final line = _lines[index];

                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: line.itemId,
                                decoration: const InputDecoration(
                                  labelText: 'الصنف *',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                isExpanded: true,
                                items: items.map<DropdownMenuItem<int>>((it) {
                                  return DropdownMenuItem<int>(
                                    value: it['id'] as int,
                                    child: Text('${it['name']} (${it['unit']})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      line.itemId = val;
                                      final itemObj = items.firstWhere((it) => it['id'] == val);
                                      line.costController.text = (itemObj['purchase_price'] ?? 0).toString();
                                    });
                                  }
                                },
                              ),
                            ),
                            if (_lines.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                onPressed: () => _removeLine(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: line.qtyController,
                                label: 'الكمية المنقولة *',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: line.costController,
                                label: 'تكلفة الوحدة',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _notesController,
                label: 'ملاحظات الحركة',
                hint: 'سبب المناقلة / إذن استلام...',
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
                        'حفظ وترحيل حركة المخزون',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
