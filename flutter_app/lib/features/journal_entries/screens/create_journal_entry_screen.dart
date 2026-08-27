import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../cost_centers/providers/cost_centers_provider.dart';
import '../providers/journal_entries_provider.dart';

class CreateJournalEntryScreen extends StatefulWidget {
  const CreateJournalEntryScreen({super.key});

  @override
  State<CreateJournalEntryScreen> createState() => _CreateJournalEntryScreenState();
}

class _JournalLineInput {
  int? accountId;
  int? costCenterId;
  String description = '';
  final debitController = TextEditingController(text: '0');
  final creditController = TextEditingController(text: '0');

  double get debit => double.tryParse(debitController.text) ?? 0.0;
  double get credit => double.tryParse(creditController.text) ?? 0.0;

  void dispose() {
    debitController.dispose();
    creditController.dispose();
  }
}

class _CreateJournalEntryScreenState extends State<CreateJournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateTime.now().toString().substring(0, 10),
  );

  int _currencyId = 1;
  double _exchangeRate = 1.0;

  final List<_JournalLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    // Default 2 lines
    _addLine();
    _addLine();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().fetchAccounts();
      context.read<AccountsProvider>().fetchCurrencies();
      context.read<CostCentersProvider>().fetchCostCenters();
    });
  }

  void _addLine() {
    final line = _JournalLineInput();
    line.debitController.addListener(() => setState(() {}));
    line.creditController.addListener(() => setState(() {}));
    setState(() {
      _lines.add(line);
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن يحتوي القيد على طرفين على الأقل')),
      );
      return;
    }
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  @override
  void dispose() {
    _refController.dispose();
    _descController.dispose();
    _dateController.dispose();
    for (var l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _totalDebit => _lines.fold(0.0, (sum, l) => sum + l.debit);
  double get _totalCredit => _lines.fold(0.0, (sum, l) => sum + l.credit);
  bool get _isBalanced =>
      (_totalDebit - _totalCredit).abs() < 0.001 && _totalDebit > 0;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('القيد غير متوازن! يجب أن يتساوى إجمالي المدين مع إجمالي الدائن'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    for (var l in _lines) {
      if (l.accountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الحساب لجميع أطراف القيد')),
        );
        return;
      }
    }

    final data = {
      'date': _dateController.text,
      'reference': _refController.text.isEmpty ? null : _refController.text,
      'description': _descController.text,
      'currency_id': _currencyId,
      'exchange_rate': _exchangeRate,
      'lines': _lines.map((l) {
        return {
          'account_id': l.accountId,
          'cost_center_id': l.costCenterId,
          'description': l.description.isEmpty ? _descController.text : l.description,
          'debit': l.debit,
          'credit': l.credit,
        };
      }).toList(),
    };

    final jeProvider = context.read<JournalEntriesProvider>();
    final success = await jeProvider.createJournalEntry(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ وترحيل قيد اليومية بنجاح')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = context.watch<AccountsProvider>().accounts;
    final costCenters = context.watch<CostCentersProvider>().costCenters;
    final jeProvider = context.watch<JournalEntriesProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'إنشاء قيد يومية عام'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Entry Header Information
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _dateController,
                            label: 'تاريخ القيد *',
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
                            controller: _refController,
                            label: 'الرقم المرجعي / السند',
                            hint: 'تلقائي إذا ترك فارغاً',
                            prefixIcon: Icons.tag,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _descController,
                      label: 'البيان / شرح القيد العام *',
                      hint: 'مثال: إثبات مصاريف عمومية / تسوية حساب...',
                      prefixIcon: Icons.description_outlined,
                      validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال البيان' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Journal Lines Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'أطراف وحركات القيد (Debit / Credit)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('إضافة طرف جديد'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lines List
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
                                value: line.accountId,
                                decoration: const InputDecoration(
                                  labelText: 'الحساب المالي *',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                isExpanded: true,
                                items: accounts.map<DropdownMenuItem<int>>((a) {
                                  return DropdownMenuItem<int>(
                                    value: a['id'] as int,
                                    child: Text('${a['code']} - ${a['name']}'),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => line.accountId = val),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                              onPressed: () => _removeLine(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Debit Field
                            Expanded(
                              child: CustomTextField(
                                controller: line.debitController,
                                label: 'مدين (Debit)',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) {
                                  if (double.tryParse(val) != null && double.parse(val) > 0) {
                                    line.creditController.text = '0';
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Credit Field
                            Expanded(
                              child: CustomTextField(
                                controller: line.creditController,
                                label: 'دائن (Credit)',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) {
                                  if (double.tryParse(val) != null && double.parse(val) > 0) {
                                    line.debitController.text = '0';
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Cost Center & Line note
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: line.costCenterId,
                                decoration: const InputDecoration(
                                  labelText: 'مركز التكلفة (اختياري)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                onChanged: (val) => setState(() => line.costCenterId = val),
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

              // Balanced Status Summary Box
              GlassCard(
                padding: const EdgeInsets.all(18),
                color: _isBalanced
                    ? AppColors.secondary.withOpacity(isDark ? 0.15 : 0.08)
                    : AppColors.danger.withOpacity(isDark ? 0.15 : 0.08),
                border: Border.all(
                  color: _isBalanced ? AppColors.secondary : AppColors.danger,
                  width: 1.5,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المدين:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          Formatters.formatCurrency(_totalDebit),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي الدائن:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          Formatters.formatCurrency(_totalCredit),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isBalanced ? Icons.check_circle_rounded : Icons.warning_rounded,
                              color: _isBalanced ? AppColors.secondary : AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isBalanced ? 'القيد متوازن وجاهز للترحيل' : 'القيد غير متوازن (الفارق: ${Formatters.formatCurrency((_totalDebit - _totalCredit).abs())})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isBalanced ? AppColors.secondaryDark : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: jeProvider.isLoading || !_isBalanced ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: jeProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ وترحيل القيد المحاسبي',
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
