import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../parties/providers/parties_provider.dart';
import '../../cost_centers/providers/cost_centers_provider.dart';
import '../providers/vouchers_provider.dart';

class CreateVoucherScreen extends StatefulWidget {
  final String initialType;
  const CreateVoucherScreen({super.key, this.initialType = 'receipt'});

  @override
  State<CreateVoucherScreen> createState() => _CreateVoucherScreenState();
}

class _CreateVoucherScreenState extends State<CreateVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _voucherNumberController = TextEditingController();
  final _dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final _amountController = TextEditingController();
  final _checkNumberController = TextEditingController();
  final _checkDateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final _bankNameController = TextEditingController();
  final _notesController = TextEditingController();

  late String _type; // receipt, payment
  String _paymentMethod = 'cash'; // cash, bank, check

  int? _selectedAccountId; // Treasury / Bank / Cash account
  int? _selectedPartyId; // Customer / Vendor
  int? _selectedCostCenterId;
  int _selectedCurrencyId = 1;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().fetchAccounts();
      context.read<AccountsProvider>().fetchCurrencies();
      context.read<PartiesProvider>().fetchParties();
      context.read<CostCentersProvider>().fetchCostCenters();
    });
  }

  @override
  void dispose() {
    _voucherNumberController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _checkNumberController.dispose();
    _checkDateController.dispose();
    _bankNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار حساب الصندوق أو البنك')),
      );
      return;
    }

    if (_selectedPartyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الطرف (العميل أو المورد)')),
      );
      return;
    }

    final data = {
      'type': _type,
      'payment_method': _paymentMethod,
      'date': _dateController.text,
      'amount': double.tryParse(_amountController.text) ?? 0,
      'account_id': _selectedAccountId,
      'party_id': _selectedPartyId,
      'cost_center_id': _selectedCostCenterId,
      'currency_id': _selectedCurrencyId,
      'exchange_rate': 1.0,
      'check_number': _paymentMethod == 'check' ? _checkNumberController.text : null,
      'check_date': _paymentMethod == 'check' ? _checkDateController.text : null,
      'bank_name': _paymentMethod == 'check' ? _bankNameController.text : null,
      'notes': _notesController.text,
    };

    final vouchersProvider = context.read<VouchersProvider>();
    final success = await vouchersProvider.createVoucher(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == 'receipt' ? 'تم حفظ سند القبض وترحيل القيد بنجاح' : 'تم حفظ سند الصرف وترحيل القيد بنجاح'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceipt = _type == 'receipt';
    final accounts = context.watch<AccountsProvider>().accounts;
    final parties = context.watch<PartiesProvider>().parties;
    final costCenters = context.watch<CostCentersProvider>().costCenters;
    final vouchersProvider = context.watch<VouchersProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: isReceipt ? 'إنشاء سند قبض مالي (Receipt)' : 'إنشاء سند صرف مالي (Payment)',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector Toggle (Receipt / Payment)
              GlassCard(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _type = 'receipt'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isReceipt ? AppColors.secondary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                color: isReceipt ? Colors.white : AppColors.secondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'سند قبض (Receipt)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isReceipt ? Colors.white : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _type = 'payment'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isReceipt ? AppColors.danger : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                color: !isReceipt ? Colors.white : AppColors.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'سند صرف (Payment)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !isReceipt ? Colors.white : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Voucher Details Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Amount
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _dateController,
                            label: 'تاريخ السند *',
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
                            controller: _amountController,
                            label: 'المبلغ الإجمالي *',
                            hint: '0.00',
                            prefixIcon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء إدخال المبلغ';
                              if ((double.tryParse(v) ?? 0) <= 0) return 'يجب أن يكون المبلغ أكبر من صفر';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Method (Cash, Bank, Check)
                    const Text(
                      'طريقة الدفع / التحصيل *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('نقداً (Cash)')),
                            selected: _paymentMethod == 'cash',
                            onSelected: (_) => setState(() => _paymentMethod = 'cash'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('بنكي (Bank)')),
                            selected: _paymentMethod == 'bank',
                            onSelected: (_) => setState(() => _paymentMethod = 'bank'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('شيك (Check)')),
                            selected: _paymentMethod == 'check',
                            onSelected: (_) => setState(() => _paymentMethod = 'check'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cash / Bank Account Selector
                    const Text(
                      'حساب الصندوق أو البنك (الخزينة) *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedAccountId,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                      isExpanded: true,
                      items: accounts.map<DropdownMenuItem<int>>((a) {
                        return DropdownMenuItem<int>(
                          value: a['id'] as int,
                          child: Text('${a['code']} - ${a['name']}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
                    const SizedBox(height: 16),

                    // Party (Customer / Vendor) Selector
                    Text(
                      isReceipt ? 'المستلم منه (العميل / الطرف) *' : 'المدفوع له (المورد / الطرف) *',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedPartyId,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                      isExpanded: true,
                      items: parties.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text('${p['name']} (${p['type'] == 'customer' ? 'عميل' : 'مورد'})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPartyId = val),
                    ),
                    const SizedBox(height: 16),

                    // Check Details Section (If Check is selected)
                    if (_paymentMethod == 'check') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.fact_check, color: AppColors.accent, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'بيانات الشيك (سيتم إدراجه تلقائياً بحافظة الشيكات)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _checkNumberController,
                                    label: 'رقم الشيك *',
                                    hint: '100234',
                                    validator: (v) => (_paymentMethod == 'check' && (v == null || v.isEmpty))
                                        ? 'الرجاء إدخال رقم الشيك'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _bankNameController,
                                    label: 'اسم البنك المسحوب عليه',
                                    hint: 'بنك الراجحي / الرياض',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _checkDateController,
                              label: 'تاريخ استحقاق الشيك *',
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
                                  _checkDateController.text = picked.toString().substring(0, 10);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Cost Center Selector
                    const Text(
                      'مركز التكلفة (اختياري)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      value: _selectedCostCenterId,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.donut_large_outlined)),
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

                    // Notes
                    CustomTextField(
                      controller: _notesController,
                      label: 'ملاحظات وبيان السند',
                      hint: 'دفعة نقدية تحت الحساب / سداد فاتورة...',
                      prefixIcon: Icons.notes,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: vouchersProvider.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isReceipt ? AppColors.secondary : AppColors.danger,
                ),
                child: vouchersProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isReceipt ? 'حفظ وترحيل سند القبض' : 'حفظ وترحيل سند الصرف',
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
