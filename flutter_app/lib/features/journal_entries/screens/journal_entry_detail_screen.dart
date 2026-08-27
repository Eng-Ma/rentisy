import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/journal_entries_provider.dart';

class JournalEntryDetailScreen extends StatefulWidget {
  final int entryId;
  const JournalEntryDetailScreen({super.key, required this.entryId});

  @override
  State<JournalEntryDetailScreen> createState() => _JournalEntryDetailScreenState();
}

class _JournalEntryDetailScreenState extends State<JournalEntryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalEntriesProvider>().fetchEntryDetail(widget.entryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jeProvider = context.watch<JournalEntriesProvider>();
    final entry = jeProvider.currentEntry;

    return Scaffold(
      appBar: CustomAppBar(title: 'تفاصيل قيد اليومية #${widget.entryId}'),
      body: jeProvider.isLoading || entry == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Entry Summary Card
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry['reference'] ?? 'JE-${entry['id']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              Formatters.formatDate(entry['date']),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          entry['description'] ?? 'بدون بيان',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'أطراف القيد (Lines)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Table of lines
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? AppColors.darkSurface : AppColors.lightDivider,
                        ),
                        columns: const [
                          DataColumn(label: Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('مدين', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('دائن', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: ((entry['lines'] as List?) ?? []).map((l) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l['account']?['name'] ?? 'حساب',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text(
                                      l['account']?['code'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(l['debit']),
                                  style: TextStyle(
                                    fontWeight: (double.tryParse(l['debit'].toString()) ?? 0) > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: (double.tryParse(l['debit'].toString()) ?? 0) > 0
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  Formatters.formatCurrency(l['credit']),
                                  style: TextStyle(
                                    fontWeight: (double.tryParse(l['credit'].toString()) ?? 0) > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: (double.tryParse(l['credit'].toString()) ?? 0) > 0
                                        ? AppColors.purple
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
