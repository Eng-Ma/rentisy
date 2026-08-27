import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import 'account_statement_report.dart';
import 'trial_balance_report.dart';
import 'income_statement_report.dart';
import 'party_statement_report.dart';
import 'aging_report.dart';
import 'cost_centers_report.dart';
import 'checks_report.dart';
import 'stock_movement_report.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_ReportCardData> reports = [
      _ReportCardData(
        title: 'كشف حساب تفصيلي (Account Statement)',
        description: 'استخراج كشف حساب مالي لحساب محدد مع الرصيد التراكمي المتحرك والتصفية بالتاريخ',
        icon: Icons.account_balance_outlined,
        color: AppColors.primary,
        screen: const AccountStatementReport(),
      ),
      _ReportCardData(
        title: 'ميزان المراجعة (Trial Balance)',
        description: 'ميزان المراجعة لجميع الحسابات بالمجاميع والأرصدة المدين والدائن والتوازن المالي',
        icon: Icons.balance_rounded,
        color: AppColors.secondaryDark,
        screen: const TrialBalanceReport(),
      ),
      _ReportCardData(
        title: 'قائمة الدخل والأرباح (Income Statement)',
        description: 'تقرير الأرباح والخسائر المقارن بين الإيرادات والمصروفات وصافي الدخل',
        icon: Icons.show_chart_rounded,
        color: AppColors.secondary,
        screen: const IncomeStatementReport(),
      ),
      _ReportCardData(
        title: 'كشف حساب عميل / مورد (Party Statement)',
        description: 'كشف مالي كامل لفواتير وحركات عميل أو مورد ومشترياته ورصيده المستحق',
        icon: Icons.person_search_rounded,
        color: AppColors.purple,
        screen: const PartyStatementReport(),
      ),
      _ReportCardData(
        title: 'تقرير أعمار الديون (Debt Aging Report)',
        description: 'تحليل أعمار ديون العملاء والموردين على فترات (0-30، 31-60، 61-90، +90 يوماً)',
        icon: Icons.history_toggle_off_rounded,
        color: AppColors.danger,
        screen: const AgingReport(),
      ),
      _ReportCardData(
        title: 'كشف مراكز التكلفة (Cost Centers)',
        description: 'كشف تحليلي بالمصروفات والإيرادات المسندة لكل مركز تكلفة ومشروع',
        icon: Icons.donut_large_rounded,
        color: AppColors.accent,
        screen: const CostCentersReport(),
      ),
      _ReportCardData(
        title: 'تقرير حافظة الشيكات (Checks Status)',
        description: 'إحصائيات الشيكات الواردة والصادرة والشيكات برسم التحصيل والمحصلة والمجيرة',
        icon: Icons.fact_check_outlined,
        color: AppColors.info,
        screen: const ChecksReport(),
      ),
      _ReportCardData(
        title: 'حركة ومخزون الأصناف (Stock Movement)',
        description: 'تقرير حركة الصنف التفصيلية من وارد ومشتريات ومبيعات وصادر ومناقلات',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF0D9488),
        screen: const StockMovementReport(),
      ),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'التقارير المالية والمستودعية الشاملة'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hub Banner
            GlassCard(
              padding: const EdgeInsets.all(20),
              gradient: isDark
                  ? const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)])
                  : const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF)]),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              child: const Row(
                children: [
                  Icon(Icons.analytics_rounded, color: AppColors.primary, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حزمة تقارير الأصيل المتقدمة (Al-Aseel Reports Suite)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'استخراج وتحليل القوائم المالية، الحسابات، الذمم، وحركات المخازن والشيكات بدقة تامة',
                          style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'اختر التقرير المطلوب:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: constraints.maxWidth > 800 ? 2.4 : 2.2,
                  ),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final rep = reports[index];

                    return GlassCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => rep.screen),
                        );
                      },
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: rep.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(rep.icon, color: rep.color, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  rep.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rep.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.lightTextSecondary),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  _ReportCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
