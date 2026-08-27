import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/journal_entries_provider.dart';
import 'create_journal_entry_screen.dart';
import 'journal_entry_detail_screen.dart';

class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalEntriesProvider>().fetchJournalEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jeProvider = context.watch<JournalEntriesProvider>();
    final entries = jeProvider.entries;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'قيود اليومية العامة (Journal Entries)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => jeProvider.fetchJournalEntries(),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateJournalEntryScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('قيد يومية جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث برقم القيد أو البيان أو المرجع...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  onPressed: () => jeProvider.fetchJournalEntries(search: _searchController.text),
                ),
              ),
              onSubmitted: (val) => jeProvider.fetchJournalEntries(search: val),
            ),
          ),

          Expanded(
            child: jeProvider.isLoading && entries.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                    ? EmptyState(
                        title: 'لا توجد قيود يومية مسجلة',
                        message: 'يمكنك إضافة قيد يومية متوازن يدوي بالضغط على الزر أدناه',
                        icon: Icons.receipt_long_outlined,
                        buttonText: 'إنشاء قيد يومية',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateJournalEntryScreen()),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final lines = (entry['lines'] as List?) ?? [];
                          final totalDebit = lines.fold<double>(
                            0.0,
                            (sum, l) => sum + (double.tryParse(l['debit']?.toString() ?? '0') ?? 0),
                          );

                          return GlassCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JournalEntryDetailScreen(entryId: entry['id']),
                                ),
                              );
                            },
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            entry['reference'] ?? 'JE-${entry['id']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          Formatters.formatDate(entry['date']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      Formatters.formatCurrency(totalDebit),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  entry['description'] ?? 'بدون بيان',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'عدد الحركات: ${lines.length} طرف (${lines.map((l) => l['account']?['name'] ?? '').take(2).join(' / ')}...)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
