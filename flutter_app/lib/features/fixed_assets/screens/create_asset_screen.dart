import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../cost_centers/providers/cost_centers_provider.dart';
import '../providers/fixed_assets_provider.dart';

class CreateAssetScreen extends StatefulWidget {
  const CreateAssetScreen({super.key});

  @override
  State<CreateAssetScreen> createState() => _CreateAssetScreenState();
}

class _CreateAssetScreenState extends State<CreateAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _purchaseDateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final _costController = TextEditingController();
  final _salvageController = TextEditingController(text: '0');
  final _usefulLifeController = TextEditingController(text: '5');
  final _rateController = TextEditingController(text: '20');
  final _notesController = TextEditingController();

  int? _selectedAssetAccountId;
  int? _selectedExpenseAccountId;
  int? _selectedAccumulatedAccountId;
  int? _selectedCostCenterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().fetchAccounts();
      context.read<CostCentersProvider>().fetchCostCenters();
    });

    _usefulLifeController.addListener(() {
      final years = double.tryParse(_usefulLifeController.text) ?? 0;
      if (years > 0) {
        _rateController.text = (100 / years).toStringAsFixed(1);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _purchaseDateController.dispose();
    _costController.dispose();
    _salvageController.dispose();
    _usefulLifeController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'purchase_date': _purchaseDateController.text,
      'purchase_cost': double.tryParse(_costController.text) ?? 0,
      'salvage_value': double.tryParse(_salvageController.text) ?? 0,
      'useful_life_years': double.tryParse(_usefulLifeController.text) ?? 5,
      'depreciation_rate': double.tryParse(_rateController.text) ?? 20,
      'asset_account_id': _selectedAssetAccountId,
      'depreciation_expense_account_id': _selectedExpenseAccountId,
      'accumulated_depreciation_account_id': _selectedAccumulatedAccountId,
      'cost_center_id': _selectedCostCenterId,
      'notes': _notesController.text.trim(),
    };

    final assetsProvider = context.read<FixedAssetsProvider>();
    final success = await assetsProvider.createFixedAsset(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الأصل الثابت بنجاح في السجل'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsProvider>().accounts;
    final costCenters = context.watch<CostCentersProvider>().costCenters;
    final assetsProvider = context.watch<FixedAssetsProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'تسجيل أصل ثابت جديد'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _codeController,
                        label: 'رمز / كود الأصل *',
                        hint: 'AST-001',
                        prefixIcon: Icons.tag,
                        validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال رمز الأصل' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _purchaseDateController,
                        label: 'تاريخ الشراء *',
                        prefixIcon: Icons.calendar_today,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            _purchaseDateController.text = picked.toString().substring(0, 10);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nameController,
                  label: 'اسم الأصل الثابت *',
                  hint: 'مثال: سيارة توصيل تويوتا / أجهزة كمبيوتر سيرفر',
                  prefixIcon: Icons.business_center_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال اسم الأصل' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _costController,
                        label: 'تكلفة الشراء الأصلية *',
                        hint: '0.00',
                        prefixIcon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'الرجاء إدخال التكلفة';
                          if ((double.tryParse(v) ?? 0) <= 0) return 'يجب أن تكون التكلفة أكبر من صفر';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _salvageController,
                        label: 'القيمة التخريدية (الخردة)',
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _usefulLifeController,
                        label: 'العمر الإنتاجي (بالسنوات) *',
                        hint: '5',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _rateController,
                        label: 'نسبة الإهلاك السنوية (%)',
                        hint: '20',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<int?>(
                  value: _selectedAssetAccountId,
                  decoration: const InputDecoration(
                    labelText: 'حساب الأصل في الشجرة',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('تحديد تلقائي')),
                    ...accounts.map<DropdownMenuItem<int?>>((a) {
                      return DropdownMenuItem<int?>(
                        value: a['id'] as int,
                        child: Text('${a['code']} - ${a['name']}'),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) => setState(() => _selectedAssetAccountId = val),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<int?>(
                  value: _selectedCostCenterId,
                  decoration: const InputDecoration(
                    labelText: 'مركز التكلفة المرتبط',
                    prefixIcon: Icon(Icons.donut_large_outlined),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('بدون مركز تكلفة')),
                    ...costCenters.map<DropdownMenuItem<int?>>((cc) {
                      return DropdownMenuItem<int?>(
                        value: cc['id'] as int,
                        child: Text('${cc['code']} - ${cc['name']}'),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) => setState(() => _selectedCostCenterId = val),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _notesController,
                  label: 'ملاحظات',
                  hint: 'رقم الشاسيه / الضمان / موقع الأصل...',
                  prefixIcon: Icons.notes,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: assetsProvider.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: assetsProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تسجيل الأصل الثابت',
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
