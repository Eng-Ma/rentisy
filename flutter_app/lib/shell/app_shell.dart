import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_layout.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';

// Screens
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../features/accounts/screens/accounts_screen.dart';
import '../features/journal_entries/screens/journal_entries_screen.dart';
import '../features/vouchers/screens/vouchers_screen.dart';
import '../features/checks/screens/checks_screen.dart';
import '../features/invoices/screens/invoices_screen.dart';
import '../features/quotations/screens/quotations_screen.dart';
import '../features/inventory/screens/items_screen.dart';
import '../features/inventory/screens/stock_transfers_screen.dart';
import '../features/fixed_assets/screens/fixed_assets_screen.dart';
import '../features/cost_centers/screens/cost_centers_screen.dart';
import '../features/parties/screens/parties_screen.dart';
import '../features/reports/screens/reports_hub_screen.dart';
import '../features/settings/screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<_NavSection> _navSections = [
    _NavSection(
      title: 'الرئيسية',
      icon: Icons.dashboard_rounded,
      builder: () => const DashboardScreen(),
    ),
    _NavSection(
      title: 'المساعد الذكي (AI Agent)',
      icon: Icons.auto_awesome_rounded,
      builder: () => const AiAssistantScreen(),
    ),
    _NavSection(
      title: 'شجرة الحسابات',
      icon: Icons.account_tree_rounded,
      builder: () => const AccountsScreen(),
    ),
    _NavSection(
      title: 'قيود اليومية',
      icon: Icons.receipt_long_rounded,
      builder: () => const JournalEntriesScreen(),
    ),
    _NavSection(
      title: 'سندات القبض والصرف',
      icon: Icons.payments_rounded,
      builder: () => const VouchersScreen(),
    ),
    _NavSection(
      title: 'حافظة الشيكات',
      icon: Icons.fact_check_rounded,
      builder: () => const ChecksScreen(),
    ),
    _NavSection(
      title: 'الفواتير والمبيعات',
      icon: Icons.point_of_sale_rounded,
      builder: () => const InvoicesScreen(),
    ),
    _NavSection(
      title: 'عروض الأسعار',
      icon: Icons.request_quote_rounded,
      builder: () => const QuotationsScreen(),
    ),
    _NavSection(
      title: 'الأصناف والمستودع',
      icon: Icons.inventory_2_rounded,
      builder: () => const ItemsScreen(),
    ),
    _NavSection(
      title: 'مناقلات المخزون',
      icon: Icons.swap_horiz_rounded,
      builder: () => const StockTransfersScreen(),
    ),
    _NavSection(
      title: 'العملاء والموردين',
      icon: Icons.people_alt_rounded,
      builder: () => const PartiesScreen(),
    ),
    _NavSection(
      title: 'الأصول الثابتة',
      icon: Icons.business_center_rounded,
      builder: () => const FixedAssetsScreen(),
    ),
    _NavSection(
      title: 'مراكز التكلفة',
      icon: Icons.donut_large_rounded,
      builder: () => const CostCentersScreen(),
    ),
    _NavSection(
      title: 'التقارير المالية',
      icon: Icons.analytics_rounded,
      builder: () => const ReportsHubScreen(),
    ),
    _NavSection(
      title: 'الإعدادات',
      icon: Icons.settings_rounded,
      builder: () => const SettingsScreen(),
    ),
  ];

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation Rail
            Container(
              width: isDesktop ? 260 : 80,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  left: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Logo header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      mainAxisAlignment:
                          isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نظام المحاسبة',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Accounting ERP',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Navigation list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navSections.length,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      itemBuilder: (context, index) {
                        final item = _navSections[index];
                        final isSelected = _selectedIndex == index;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            selected: isSelected,
                            selectedTileColor: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              item.icon,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                              size: 22,
                            ),
                            title: isDesktop
                                ? Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary),
                                    ),
                                  )
                                : null,
                            onTap: () => _onSelect(index),
                          ),
                        );
                      },
                    ),
                  ),

                  // User bottom panel
                  const Divider(height: 1),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Text(
                                (auth.user?['name'] ?? 'A')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      auth.user?['name'] ?? 'Admin',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      auth.user?['email'] ?? 'admin@admin.com',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.lightTextSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
                                onPressed: () async {
                                  await auth.logout();
                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: _navSections[_selectedIndex].builder(),
            ),
          ],
        ),
      );
    }

    // Mobile Layout with App Drawer & Bottom Navigation Bar
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      (auth.user?['name'] ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  accountName: Text(
                    auth.user?['name'] ?? 'Admin User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(auth.user?['email'] ?? 'admin@admin.com'),
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _navSections.length,
                itemBuilder: (context, index) {
                  final item = _navSections[index];
                  final isSelected = _selectedIndex == index;

                  return ListTile(
                    selected: isSelected,
                    leading: Icon(
                      item.icon,
                      color: isSelected ? AppColors.primary : null,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onSelect(index);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _navSections[_selectedIndex].builder(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
        onDestinationSelected: (idx) {
          if (idx == 4) {
            // Open Drawer for all modules
            Scaffold.of(context).openDrawer();
          } else {
            _onSelect(idx);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'الفواتير',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'السندات',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'التقارير',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_open_rounded),
            label: 'القائمة',
          ),
        ],
      ),
    );
  }
}

class _NavSection {
  final String title;
  final IconData icon;
  final Widget Function() builder;

  _NavSection({
    required this.title,
    required this.icon,
    required this.builder,
  });
}
