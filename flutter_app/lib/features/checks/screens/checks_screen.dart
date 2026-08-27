import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../parties/providers/parties_provider.dart';
import '../providers/checks_provider.dart';
import 'create_check_screen.dart';

class ChecksScreen extends StatefulWidget {
  const ChecksScreen({super.key});

  @override
  State<ChecksScreen> createState() => _ChecksScreenState();
}

class _ChecksScreenState extends State<ChecksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final types = ['all', 'received', 'issued'];
        context.read<ChecksProvider>().setType(types[_tabController.index]);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecksProvider>().fetchChecks();
      context.read<AccountsProvider>().fetchAccounts();
      context.read<PartiesProvider>().fetchParties();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCollectDialog(dynamic check) {
    final accounts = context.read<AccountsProvider>().accounts;
    int? selectedBankAccountId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.account_balance, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('تحصيل وإيداع الشيك بالبنك'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيتم تسجيل إيداع الشيك رقم ${check['check_number']} بمبلغ ${Formatters.formatCurrency(check['amount'])} وتوليد قيد الإيداع المحاسبي آلياً.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              const Text(
                'اختر الحساب البنكي المودع فيه:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedBankAccountId,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.account_balance)),
                isExpanded: true,
                items: accounts.map<DropdownMenuItem<int>>((a) {
                  return DropdownMenuItem<int>(
                    value: a['id'] as int,
                    child: Text('${a['code']} - ${a['name']}'),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedBankAccountId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<ChecksProvider>().updateCheckStatus(
                  check['id'],
                  {
                    'status': 'collected',
                    'bank_account_id': selectedBankAccountId,
                    'collection_date': DateTime.now().toString().substring(0, 10),
                  },
                );
                if (mounted) Navigator.pop(ctx);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحصيل الشيك بنجاح وتوليد قيد الإيداع البنكي'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: const Text('تأكيد التحصيل'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndorseDialog(dynamic check) {
    final vendors = context.read<PartiesProvider>().vendors;
    int? selectedVendorId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.forward_to_inbox_rounded, color: AppColors.purple),
              SizedBox(width: 8),
              Text('تجيير الشيك إلى مورد'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تجيير الشيك رقم ${check['check_number']} بمبلغ ${Formatters.formatCurrency(check['amount'])} لسداد حساب المورد.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              const Text(
                'اختر المورد المجير له:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedVendorId,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
                isExpanded: true,
                items: vendors.map<DropdownMenuItem<int>>((v) {
                  return DropdownMenuItem<int>(
                    value: v['id'] as int,
                    child: Text(v['name']),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedVendorId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedVendorId == null) return;
                final success = await context.read<ChecksProvider>().updateCheckStatus(
                  check['id'],
                  {
                    'status': 'endorsed',
                    'endorsed_party_id': selectedVendorId,
                  },
                );
                if (mounted) Navigator.pop(ctx);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تجيير الشيك للمورد بنجاح وتسوية رصيده'),
                      backgroundColor: AppColors.purple,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              child: const Text('تأكيد التجيير'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBounceDialog(dynamic check) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: AppColors.danger),
            SizedBox(width: 8),
            Text('إرجاع الشيك (مرتجع / بدون رصيد)'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الشيك رقم ${check['check_number']} كشيك مرتجع؟',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<ChecksProvider>().updateCheckStatus(
                check['id'],
                {'status': 'bounced'},
              );
              if (mounted) Navigator.pop(ctx);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تغيير حالة الشيك إلى مرتجع'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تأكيد الإرجاع'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checksProvider = context.watch<ChecksProvider>();
    final checks = checksProvider.checks;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'حافظة الشيكات (Checks Portfolio)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => checksProvider.fetchChecks(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'جميع الشيكات'),
            Tab(text: 'شيكات واردة (Received)'),
            Tab(text: 'شيكات صادرة (Issued)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCheckScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة شيك للحافظة'),
        backgroundColor: AppColors.primary,
      ),
      body: checksProvider.isLoading && checks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : checks.isEmpty
              ? EmptyState(
                  title: 'لا توجد شيكات مسجلة في الحافظة',
                  message: 'يمكنك إضافة شيكات واردة أو صادرة ومتابعة دورة تحصيلها وتجييرها',
                  icon: Icons.fact_check_outlined,
                  buttonText: 'إضافة شيك جديد',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateCheckScreen()),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: checks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final check = checks[index];
                    final isReceived = check['type'] == 'received';
                    final isUnderCollection = check['status'] == 'under_collection';

                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.fact_check,
                                    color: isReceived ? AppColors.secondaryDark : AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'شيك #${check['check_number']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(status: check['status'] ?? 'under_collection'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                check['bank_name'] ?? 'البنك',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                Formatters.formatCurrency(check['amount']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'الطرف: ${check['party']?['name'] ?? check['drawer_name'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'استحقاق: ${Formatters.formatDate(check['due_date'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),

                          // Quick Action Buttons for Under Collection Checks
                          if (isUnderCollection) ...[
                            const Divider(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showCollectDialog(check),
                                  icon: const Icon(Icons.account_balance, size: 14),
                                  label: const Text('تحصيل بالبنك'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isReceived)
                                  ElevatedButton.icon(
                                    onPressed: () => _showEndorseDialog(check),
                                    icon: const Icon(Icons.forward_to_inbox, size: 14),
                                    label: const Text('تجيير لمورد'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.purple,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => _showBounceDialog(check),
                                  icon: const Icon(Icons.report_problem, size: 14, color: AppColors.danger),
                                  label: const Text('إرجاع الشيك', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.danger),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
