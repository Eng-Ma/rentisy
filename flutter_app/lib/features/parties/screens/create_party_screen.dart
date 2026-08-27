import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/parties_provider.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _type = 'customer';
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'type': _type,
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      'account_id': _selectedAccountId,
    };

    final partiesProvider = context.read<PartiesProvider>();
    final success = await partiesProvider.createParty(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == 'customer' ? 'تمت إضافة العميل بنجاح' : 'تمت إضافة المورد بنجاح'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsProvider>().accounts;
    final partiesProvider = context.watch<PartiesProvider>();
    final isCustomer = _type == 'customer';

    return Scaffold(
      appBar: CustomAppBar(title: isCustomer ? 'إضافة عميل جديد' : 'إضافة مورد جديد'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('عميل (Customer)')),
                        selected: isCustomer,
                        onSelected: (_) => setState(() => _type = 'customer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('مورد (Vendor)')),
                        selected: !isCustomer,
                        onSelected: (_) => setState(() => _type = 'vendor'),
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
                      controller: _nameController,
                      label: isCustomer ? 'اسم العميل / الشركة *' : 'اسم المورد / الشركة *',
                      hint: 'مثال: شركة النور للتجارة / أحمد محمد',
                      prefixIcon: Icons.business,
                      validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف / الجوال',
                      hint: '05xxxxxxxx',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _addressController,
                      label: 'العنوان والمدينة',
                      hint: 'الرياض - حي الملز - شارع...',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int?>(
                      value: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'الحساب المرتبط في الشجرة (اختياري)',
                        prefixIcon: Icon(Icons.account_tree_outlined),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('ربط تلقائي بحسابات العملاء/الموردين')),
                        ...accounts.map<DropdownMenuItem<int?>>((a) {
                          return DropdownMenuItem<int?>(
                            value: a['id'] as int,
                            child: Text('${a['code']} - ${a['name']}'),
                          );
                        }).toList(),
                      ],
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: partiesProvider.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: partiesProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isCustomer ? 'حفظ بيانات العميل' : 'حفظ بيانات المورد',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
