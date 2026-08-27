import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../parties/providers/parties_provider.dart';
import '../providers/invoices_provider.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String initialType;
  const CreateInvoiceScreen({super.key, this.initialType = 'sale'});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _InvoiceLineInput {
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

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final _notesController = TextEditingController();

  late String _type;
  int? _selectedPartyId;
  int? _selectedStoreId;

  final List<_InvoiceLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _addLine();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
      context.read<InventoryProvider>().fetchStores();
      context.read<PartiesProvider>().fetchParties();
    });
  }

  void _addLine() {
    final line = _InvoiceLineInput();
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
    _notesController.dispose();
    for (var l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _totalAmount => _lines.fold(0.0, (sum, l) => sum + l.totalPrice);

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPartyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار العميل أو المورد')),
      );
      return;
    }

    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار المستودع')),
      );
      return;
    }

    for (var l in _lines) {
      if (l.itemId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد الصنف في جميع أسطر الفاتورة')),
        );
        return;
      }
    }

    final data = {
      'type': _type,
      'date': _dateController.text,
      'party_id': _selectedPartyId,
      'store_id': _selectedStoreId,
      'notes': _notesController.text,
      'lines': _lines.map((l) {
        return {
          'item_id': l.itemId,
          'quantity': l.quantity,
          'unit_price': l.unitPrice,
        };
      }).toList(),
    };

    final invoicesProvider = context.read<InvoicesProvider>();
    final result = await invoicesProvider.createInvoice(data);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الفاتورة بنجاح وتحديث أرصدة المخازن والقيود المحاسبية'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = context.watch<InventoryProvider>().items;
    final stores = context.watch<InventoryProvider>().stores;
    final parties = context.watch<PartiesProvider>().parties;
    final invoicesProvider = context.watch<InvoicesProvider>();

    if (_selectedStoreId == null && stores.isNotEmpty) {
      _selectedStoreId = stores.first['id'];
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _type == 'sale'
            ? 'إنشاء فاتورة مبيعات'
            : _type == 'purchase'
                ? 'إنشاء فاتورة مشتريات'
                : 'إنشاء فاتورة مردودات',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Invoice Type Selector
              GlassCard(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('فاتورة مبيعات'),
                      selected: _type == 'sale',
                      onSelected: (_) => setState(() => _type = 'sale'),
                    ),
                    ChoiceChip(
                      label: const Text('فاتورة مشتريات'),
                      selected: _type == 'purchase',
                      onSelected: (_) => setState(() => _type = 'purchase'),
                    ),
                    ChoiceChip(
                      label: const Text('مردود مبيعات'),
                      selected: _type == 'sale_return',
                      onSelected: (_) => setState(() => _type = 'sale_return'),
                    ),
                    ChoiceChip(
                      label: const Text('مردود مشتريات'),
                      selected: _type == 'purchase_return',
                      onSelected: (_) => setState(() => _type = 'purchase_return'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Header Details
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _dateController,
                            label: 'تاريخ الفاتورة *',
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
                          child: DropdownButtonFormField<int>(
                            value: _selectedStoreId,
                            decoration: const InputDecoration(
                              labelText: 'المستودع *',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            isExpanded: true,
                            items: stores.map<DropdownMenuItem<int>>((s) {
                              return DropdownMenuItem<int>(
                                value: s['id'] as int,
                                child: Text(s['name']),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedStoreId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Party Dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedPartyId,
                      decoration: InputDecoration(
                        labelText: _type.contains('sale') ? 'العميل (المشتري) *' : 'المورد (البائع) *',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      isExpanded: true,
                      items: parties.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text('${p['name']} (${p['type'] == 'customer' ? 'عميل' : 'مورد'})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPartyId = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Line Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'بنود وأصناف الفاتورة',
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

              // Line Items List
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  labelText: 'الصنف من المستودع *',
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
                                      if (_type.contains('sale')) {
                                        line.priceController.text = (itemObj['sales_price'] ?? 0).toString();
                                      } else {
                                        line.priceController.text = (itemObj['purchase_price'] ?? 0).toString();
                                      }
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
                            // Quantity
                            Expanded(
                              child: CustomTextField(
                                controller: line.qtyController,
                                label: 'الكمية *',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Unit Price
                            Expanded(
                              child: CustomTextField(
                                controller: line.priceController,
                                label: 'سعر الوحدة *',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Line Total
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

              // Total Summary Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'المجموع الكلي للفاتورة:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.formatCurrency(_totalAmount),
                          style: const TextStyle(
                            fontSize: 24,
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
                label: 'ملاحظات الفاتورة',
                hint: 'شروط الدفع / التوصيل...',
                prefixIcon: Icons.notes,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: invoicesProvider.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: invoicesProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ وترحيل الفاتورة',
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
