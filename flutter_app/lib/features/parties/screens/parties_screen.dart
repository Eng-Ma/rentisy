import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/parties_provider.dart';
import 'create_party_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final _typeTabs = const [
    {'key': 'all', 'label': 'جميع الأطراف'},
    {'key': 'customer', 'label': 'العملاء (Customers)'},
    {'key': 'vendor', 'label': 'الموردين (Vendors)'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _typeTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final key = _typeTabs[_tabController.index]['key']!;
        context.read<PartiesProvider>().setType(key);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartiesProvider>().fetchParties();
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
    final partiesProvider = context.watch<PartiesProvider>();
    final parties = partiesProvider.parties;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'دليل العملاء والموردين (Parties)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => partiesProvider.fetchParties(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
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
            MaterialPageRoute(builder: (_) => const CreatePartyScreen()),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('إضافة طرف جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث باسم العميل أو رقم الهاتف أو العنوان...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => partiesProvider.fetchParties(search: _searchController.text),
                ),
              ),
              onSubmitted: (val) => partiesProvider.fetchParties(search: val),
            ),
          ),
          Expanded(
            child: partiesProvider.isLoading && parties.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : parties.isEmpty
                    ? EmptyState(
                        title: 'لا يوجد عملاء أو موردين مسجلين',
                        message: 'يمكنك إضافة عملاء وموردين وربطهم بحسابات الشجرة لمتابعة أرصدتهم',
                        icon: Icons.people_alt_outlined,
                        buttonText: 'إضافة عميل / مورد',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreatePartyScreen()),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: parties.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final party = parties[index];
                          final isCustomer = party['type'] == 'customer';

                          return GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isCustomer
                                      ? AppColors.primary.withOpacity(0.15)
                                      : AppColors.purple.withOpacity(0.15),
                                  child: Icon(
                                    isCustomer ? Icons.person : Icons.store,
                                    color: isCustomer ? AppColors.primary : AppColors.purple,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            party['name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isCustomer
                                                  ? AppColors.primary.withOpacity(0.12)
                                                  : AppColors.purple.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isCustomer ? 'عميل (Customer)' : 'مورد (Vendor)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isCustomer ? AppColors.primary : AppColors.purple,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (party['phone'] != null && party['phone'].toString().isNotEmpty)
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 14, color: AppColors.lightTextSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              party['phone'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (party['address'] != null && party['address'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.lightTextSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              party['address'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
