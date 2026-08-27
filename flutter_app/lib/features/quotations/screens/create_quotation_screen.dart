import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../parties/providers/parties_provider.dart';
import '../providers/quotations_provider.dart';

class CreateQuotationScreen extends StatefulWidget {
  const CreateQuotationScreen({super.key});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _QuoteLineInput {
  int? itemId;
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController(text: '0');

  double get quantity => double.tryParse(qtyController.text) ?? 1.0;
  double get unitPrice => double.tryParse(priceController.text) ?? 0.0;
  double get totalPrice => quantity * unitPrice;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final _expiryDateController = TextEditingController(
    text: DateTime.now().add(const Duration(days: 30)).toString().substring(0, 10),
  );
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  int? _selectedPartyId;
  int? _selectedStoreId;

  final List<_QuoteLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    _addLine();
    _discountController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
      context.read<InventoryProvider>().fetchStores();
      context.read<PartiesProvider>().fetchParties();
    });
  }

  void _addLine() {
    final line = _QuoteLineInput();
    line.qtyController.addListener(() => setState(() {}));
    line.priceController.addListener(() => setState(() {}));
    setState(() {
      _lines.add(line);
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
    _expiryDateController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    for (var l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _lines.fold(0.0, (sum, l) => sum + l.totalPrice);
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _totalAmount => (_subtotal - _discount).clamp(0.0, double.infinity);

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPartyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار العميل المقدم له عرض السعر')),
      );
      return;
    }

    for (var l in _lines) {
      if (l.itemId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد الصنف لجميع بنود عرض السعر')),
        );
        return;
      }
    }

    final data = {
      'party_id': _selectedPartyId,
      'store_id': _selectedStoreId,
      'date': _dateController.text,
      'expiry_date': _expiryDateController.text,
      'discount': _discount,
      'notes': _notesController.text,
      'lines': _lines.map((l) {
        return {
          'item_id': l.itemId,
          'quantity': l.quantity,
          'unit_price': l.unitPrice,
        };
      }).toList(),
    };

    final qProvider = context.read<QuotationsProvider>();
    final success = await qProvider.createQuotation(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء عرض السعر بنجاح'),
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
    final parties = context.watch<PartiesProvider>().customers.isNotEmpty
        ? context.watch<PartiesProvider>().customers
        : context.watch<PartiesProvider>().parties;
    final qProvider = context.watch<QuotationsProvider>();

    if (_selectedStoreId == null && stores.isNotEmpty) {
      _selectedStoreId = stores.first['id'];
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'إنشاء عرض أسعار جديد'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedPartyId,
                      decoration: const InputDecoration(
                        labelText: 'العميل *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      isExpanded: true,
                      items: parties.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text(p['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPartyId = val),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _dateController,
                            label: 'تاريخ العرض *',
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _expiryDateController,
                            label: 'تاريخ الانتهاء',
                            prefixIcon: Icons.event_available,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                _expiryDateController.text = picked.toString().substring(0, 10);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lines Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'بنود وأسعار الأصناف',
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
                              backgroundColor: AppColors.info.withOpacity(0.15),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
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
                                      line.priceController.text = (itemObj['sales_price'] ?? 0).toString();
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
                                label: 'الكمية *',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: line.priceController,
                                label: 'سعر الوحدة *',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الإجمالي',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    Formatters.formatCurrency(line.totalPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
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

              // Summary
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الجزئي:'),
                        Text(Formatters.formatCurrency(_subtotal)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('خصم تجاري:'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _discountController,
                            label: '',
                            hint: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'المجموع النهائي:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.formatCurrency(_totalAmount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _notesController,
                label: 'ملاحظات وشروط العرض',
                hint: 'الأسعار شاملة التوصيل / ساري لمدة 30 يوماً...',
                prefixIcon: Icons.notes,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: qProvider.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: qProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ عرض السعر',
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
