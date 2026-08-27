import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../parties/providers/parties_provider.dart';
import '../providers/checks_provider.dart';

class CreateCheckScreen extends StatefulWidget {
  const CreateCheckScreen({super.key});

  @override
  State<CreateCheckScreen> createState() => _CreateCheckScreenState();
}

class _CreateCheckScreenState extends State<CreateCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _checkNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _drawerNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final _notesController = TextEditingController();

  String _type = 'received'; // received or issued
  int? _selectedPartyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartiesProvider>().fetchParties();
    });
  }

  @override
  void dispose() {
    _checkNumberController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _drawerNameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'check_number': _checkNumberController.text.trim(),
      'type': _type,
      'bank_name': _bankNameController.text.trim(),
      'branch': _branchController.text.trim(),
      'drawer_name': _drawerNameController.text.trim(),
      'amount': double.tryParse(_amountController.text) ?? 0,
      'due_date': _dueDateController.text,
      'party_id': _selectedPartyId,
      'currency_id': 1,
      'notes': _notesController.text.trim(),
    };

    final checksProvider = context.read<ChecksProvider>();
    final success = await checksProvider.createCheck(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة الشيك إلى الحافظة بنجاح'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parties = context.watch<PartiesProvider>().parties;
    final checksProvider = context.watch<ChecksProvider>();
    final isReceived = _type == 'received';

    return Scaffold(
      appBar: const CustomAppBar(title: 'إضافة شيك جديد إلى الحافظة'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Check Type Toggle (Received / Issued)
              GlassCard(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('شيك وارد (من عميل)')),
                        selected: isReceived,
                        onSelected: (_) => setState(() => _type = 'received'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('شيك صادر (لمورد)')),
                        selected: !isReceived,
                        onSelected: (_) => setState(() => _type = 'issued'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _checkNumberController,
                      label: 'رقم الشيك *',
                      hint: 'مثال: 984521',
                      prefixIcon: Icons.tag,
                      validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال رقم الشيك' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _amountController,
                            label: 'مبلغ الشيك *',
                            hint: '0.00',
                            prefixIcon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء إدخال المبلغ';
                              if ((double.tryParse(v) ?? 0) <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _dueDateController,
                            label: 'تاريخ الاستحقاق *',
                            prefixIcon: Icons.event,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                _dueDateController.text = picked.toString().substring(0, 10);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _bankNameController,
                            label: 'اسم البنك *',
                            hint: 'بنك الراجحي / الرياض',
                            prefixIcon: Icons.account_balance,
                            validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال اسم البنك' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _branchController,
                            label: 'الفرع',
                            hint: 'الفرع الرئيسي',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Party selector
                    DropdownButtonFormField<int?>(
                      value: _selectedPartyId,
                      decoration: const InputDecoration(
                        labelText: 'الطرف المرتبط (العميل أو المورد)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('طرف غير محدد')),
                        ...parties.map<DropdownMenuItem<int?>>((p) {
                          return DropdownMenuItem<int?>(
                            value: p['id'] as int,
                            child: Text('${p['name']} (${p['type'] == 'customer' ? 'عميل' : 'مورد'})'),
                          );
                        }).toList(),
                      ],
                      onChanged: (val) => setState(() => _selectedPartyId = val),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _drawerNameController,
                      label: 'الساحب / المحرر',
                      hint: 'اسم محرر الشيك',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _notesController,
                      label: 'ملاحظات',
                      hint: 'أي تفاصيل إضافية حول الشيك...',
                      prefixIcon: Icons.notes,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: checksProvider.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: checksProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ الشيك في الحافظة',
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
