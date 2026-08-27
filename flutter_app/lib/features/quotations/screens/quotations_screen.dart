import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/quotations_provider.dart';
import 'create_quotation_screen.dart';
import 'quotation_detail_screen.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _statusTabs = const [
    {'key': 'all', 'label': 'جميع العروض'},
    {'key': 'draft', 'label': 'مسودة'},
    {'key': 'sent', 'label': 'مرسل'},
    {'key': 'accepted', 'label': 'مقبول'},
    {'key': 'converted', 'label': 'محول لفاتورة'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final key = _statusTabs[_tabController.index]['key']!;
        context.read<QuotationsProvider>().setStatus(key);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationsProvider>().fetchQuotations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qProvider = context.watch<QuotationsProvider>();
    final quotations = qProvider.quotations;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'عروض الأسعار (Quotations)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => qProvider.fetchQuotations(),
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
          tabs: _statusTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('عرض سعر جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: qProvider.isLoading && quotations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : quotations.isEmpty
              ? EmptyState(
                  title: 'لا توجد عروض أسعار مسجلة',
                  message: 'يمكنك إنشاء عرض أسعار للعميل وتحويله بضغطة زر إلى فاتورة مبيعات لاحقاً',
                  icon: Icons.request_quote_outlined,
                  buttonText: 'إنشاء عرض سعر',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: quotations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final q = quotations[index];

                    return GlassCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuotationDetailScreen(quotationId: q['id']),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.request_quote_outlined,
                              color: AppColors.info,
                              size: 24,
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
                                      q['quotation_number'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(q['total_amount']),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  q['party']?['name'] ?? 'عميل عام',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    StatusBadge(status: q['status'] ?? 'draft'),
                                    const Spacer(),
                                    Text(
                                      Formatters.formatDate(q['date']),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
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
