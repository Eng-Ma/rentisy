import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/accounts_provider.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'asset';
  String _selectedBalanceType = 'debit';
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final accountsProvider = context.read<AccountsProvider>();
    final success = await accountsProvider.createAccount({
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'balance_type': _selectedBalanceType,
      'parent_id': _selectedParentId,
      'description': _descriptionController.text.trim(),
      'is_active': true,
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح وإضافته للشجرة')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsProvider = context.watch<AccountsProvider>();
    final accounts = accountsProvider.accounts;

    return Scaffold(
      appBar: const CustomAppBar(title: 'إضافة حساب جديد للشجرة'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Code & Name
                CustomTextField(
                  controller: _codeController,
                  label: 'رمز الحساب (الكود المحاسبي) *',
                  hint: 'مثال: 110101',
                  prefixIcon: Icons.tag,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال رمز الحساب' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nameController,
                  label: 'اسم الحساب *',
                  hint: 'مثال: صندوق المركز الرئيسي / بنك الراجحي',
                  prefixIcon: Icons.account_balance_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال اسم الحساب' : null,
                ),
                const SizedBox(height: 16),

                // Account Type Dropdown
                const Text(
                  'نوع الحساب *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'asset', child: Text('أصول (Assets)')),
                    DropdownMenuItem(value: 'liability', child: Text('خصوم / التزامات (Liabilities)')),
                    DropdownMenuItem(value: 'equity', child: Text('حقوق ملكية (Equity)')),
                    DropdownMenuItem(value: 'revenue', child: Text('إيرادات (Revenues)')),
                    DropdownMenuItem(value: 'expense', child: Text('مصروفات (Expenses)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedType = val;
                        // auto set default balance type
                        _selectedBalanceType = (val == 'asset' || val == 'expense') ? 'debit' : 'credit';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Balance Type (Debit / Credit)
                const Text(
                  'طبيعة رصيد الحساب *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedBalanceType,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.swap_vert)),
                  items: const [
                    DropdownMenuItem(value: 'debit', child: Text('مدين (Debit) - بطبيعته')),
                    DropdownMenuItem(value: 'credit', child: Text('دائن (Credit) - بطبيعته')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedBalanceType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Parent Account Dropdown
                const Text(
                  'الحساب الرئيسي (اختياري)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: _selectedParentId,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.account_tree_outlined)),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('حساب رئيسي مستقل (بدون حساب أب)'),
                    ),
                    ...accounts.map<DropdownMenuItem<int?>>((a) {
                      return DropdownMenuItem<int?>(
                        value: a['id'] as int,
                        child: Text('${a['code']} - ${a['name']}'),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedParentId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Notes / Description
                CustomTextField(
                  controller: _descriptionController,
                  label: 'ملاحظات وتفاصيل',
                  hint: 'أي تفاصيل إضافية حول الحساب...',
                  prefixIcon: Icons.notes,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: accountsProvider.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: accountsProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ الحساب',
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
