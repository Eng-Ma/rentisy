import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/reports_provider.dart';

class ChecksReport extends StatefulWidget {
  const ChecksReport({super.key});

  @override
  State<ChecksReport> createState() => _ChecksReportState();
}

class _ChecksReportState extends State<ChecksReport> {
  String _type = 'all';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  void _load() {
    context.read<ReportsProvider>().fetchChecksReport(type: _type, status: _status);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repProvider = context.watch<ReportsProvider>();
    final data = repProvider.checksReport;
    final stats = data?['stats'];
    final checks = (data?['checks'] as List?) ?? [];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'تقرير حافظة الشيكات (Checks Status Report)',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filters
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'نوع الشيك'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('جميع الأنواع')),
                        DropdownMenuItem(value: 'received', child: Text('شيكات واردة')),
                        DropdownMenuItem(value: 'issued', child: Text('شيكات صادرة')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _type = val);
                          _load();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'حالة الشيك'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
                        DropdownMenuItem(value: 'under_collection', child: Text('برسم التحصيل')),
                        DropdownMenuItem(value: 'collected', child: Text('محصل بالبنك')),
                        DropdownMenuItem(value: 'endorsed', child: Text('مجير لمورد')),
                        DropdownMenuItem(value: 'bounced', child: Text('مرتجع')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _status = val);
                          _load();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (repProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (stats != null) ...[
              // Stats Summary
              GlassCard(
                padding: const EdgeInsets.all(18),
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('إجمالي الواردة', Formatters.formatCurrency(stats['total_received']), AppColors.secondaryDark),
                        _buildStat('إجمالي الصادرة', Formatters.formatCurrency(stats['total_issued']), AppColors.purple),
                        _buildStat('برسم التحصيل', Formatters.formatCurrency(stats['under_collection']), AppColors.accent),
                        _buildStat('المحصلة بالبنك', Formatters.formatCurrency(stats['collected']), AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (checks.isEmpty)
                const EmptyState(title: 'لا توجد شيكات مطابقة للفلتر')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: checks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final check = checks[index];
                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            color: check['type'] == 'received' ? AppColors.secondaryDark : AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('شيك #${check['check_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    StatusBadge(status: check['status'] ?? 'under_collection'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${check['bank_name']} | ${check['party']?['name'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                    Text(
                                      Formatters.formatCurrency(check['amount']),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
