import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/accounts_provider.dart';
import 'create_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final _typeTabs = const [
    {'key': 'all', 'label': 'جميع الحسابات'},
    {'key': 'asset', 'label': 'الأصول'},
    {'key': 'liability', 'label': 'الخصوم'},
    {'key': 'equity', 'label': 'حقوق الملكية'},
    {'key': 'revenue', 'label': 'الإيرادات'},
    {'key': 'expense', 'label': 'المصروفات'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _typeTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final key = _typeTabs[_tabController.index]['key']!;
        context.read<AccountsProvider>().setTypeFilter(key);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsProvider>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsProvider = context.watch<AccountsProvider>();
    final accounts = accountsProvider.filteredAccounts;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'دليل شجرة الحسابات',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => accountsProvider.fetchAccounts(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: _typeTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة حساب جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: accountsProvider.isLoading && accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : accounts.isEmpty
              ? EmptyState(
                  title: 'لا توجد حسابات في هذا القسم',
                  message: 'يمكنك إضافة حساب مالي جديد إلى شجرة الحسابات بالضغط أدناه',
                  icon: Icons.account_tree_outlined,
                  buttonText: 'إضافة حساب جديد',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    final isDebit = acc['balance_type'] == 'debit';

                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              acc['code'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    StatusBadge(status: acc['type'] ?? 'asset'),
                                    const SizedBox(width: 8),
                                    Text(
                                      isDebit ? 'طبيعة الحساب: مدين' : 'طبيعة الحساب: دائن',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDebit ? AppColors.secondaryDark : AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (acc['parent'] != null) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'تابع لـ: ${acc['parent']['name']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.lightTextSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
