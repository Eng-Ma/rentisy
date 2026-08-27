import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/accounts/providers/accounts_provider.dart';
import 'features/journal_entries/providers/journal_entries_provider.dart';
import 'features/vouchers/providers/vouchers_provider.dart';
import 'features/checks/providers/checks_provider.dart';
import 'features/inventory/providers/inventory_provider.dart';
import 'features/invoices/providers/invoices_provider.dart';
import 'features/quotations/providers/quotations_provider.dart';
import 'features/fixed_assets/providers/fixed_assets_provider.dart';
import 'features/cost_centers/providers/cost_centers_provider.dart';
import 'features/parties/providers/parties_provider.dart';
import 'features/reports/providers/reports_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'shell/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AccountingErpApp());
}

class AccountingErpApp extends StatelessWidget {
  const AccountingErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => JournalEntriesProvider()),
        ChangeNotifierProvider(create: (_) => VouchersProvider()),
        ChangeNotifierProvider(create: (_) => ChecksProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => InvoicesProvider()),
        ChangeNotifierProvider(create: (_) => QuotationsProvider()),
        ChangeNotifierProvider(create: (_) => FixedAssetsProvider()),
        ChangeNotifierProvider(create: (_) => CostCentersProvider()),
        ChangeNotifierProvider(create: (_) => PartiesProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'نظام الأصيل للمحاسبة والمستودعات',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: auth.themeMode,
            locale: const Locale('ar'),
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const AppEntrypoint(),
          );
        },
      ),
    );
  }
}

class AppEntrypoint extends StatefulWidget {
  const AppEntrypoint({super.key});

  @override
  State<AppEntrypoint> createState() => _AppEntrypointState();
}

class _AppEntrypointState extends State<AppEntrypoint> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جارِ التحقق من جلسة العمل...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const AppShell();
    } else {
      return const LoginScreen();
    }
  }
}
