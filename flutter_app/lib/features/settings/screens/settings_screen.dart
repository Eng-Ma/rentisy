import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = context.read<AuthProvider>().baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    await context.read<AuthProvider>().updateBaseUrl(_urlController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث وحفظ عنوان الخادم بنجاح'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: const CustomAppBar(title: 'الإعدادات والاتصال بالنظام (Settings)'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Header
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      (user?['name'] ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['name'] ?? 'Admin User',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?['email'] ?? 'admin@admin.com',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'مدير النظام',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Server Connection Settings
            const Text(
              'إعدادات خادم النظام (Backend API Server)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _urlController,
                    label: 'رابط الخادم (Base API URL)',
                    hint: 'http://127.0.0.1:8000/api',
                    prefixIcon: Icons.dns_rounded,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.cloud_done_rounded, size: 16),
                        label: const Text('الخادم السحابي (codeit-gaza.space)'),
                        onPressed: () {
                          setState(() => _urlController.text = 'https://codeit-gaza.space/api');
                          _saveUrl();
                        },
                      ),
                      ActionChip(
                        label: const Text('محاكي أندرويد (10.0.2.2)'),
                        onPressed: () {
                          setState(() => _urlController.text = 'http://10.0.2.2:8000/api');
                          _saveUrl();
                        },
                      ),
                      ActionChip(
                        label: const Text('المحلي (127.0.0.1)'),
                        onPressed: () {
                          setState(() => _urlController.text = 'http://127.0.0.1:8000/api');
                          _saveUrl();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _saveUrl,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ رابط الخادم'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Theme Setting
            const Text(
              'المظهر والتخصيص (Theme)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('فاتح (Light Mode)'),
                    value: ThemeMode.light,
                    groupValue: auth.themeMode,
                    onChanged: (mode) {
                      if (mode != null) auth.setThemeMode(mode);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('داكن (Dark Mode)'),
                    value: ThemeMode.dark,
                    groupValue: auth.themeMode,
                    onChanged: (mode) {
                      if (mode != null) auth.setThemeMode(mode);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('تلقائي حسب الجهاز (System)'),
                    value: ThemeMode.system,
                    groupValue: auth.themeMode,
                    onChanged: (mode) {
                      if (mode != null) auth.setThemeMode(mode);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About System
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'نظام الأصيل الذهبي للمحاسبة والمستودعات',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الإصدار: 1.0.0 Golden Edition\nنظام ERP محاسبي متكامل يدعم المحاسبة العامة، سندات القبض والصرف، الشيكات، المستودعات، والمبيعات والمشتريات.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text(
                'تسجيل الخروج من الحساب',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
