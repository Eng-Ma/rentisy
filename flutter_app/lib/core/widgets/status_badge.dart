import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Text(
        label ?? config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _BadgeConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      // Vouchers & Invoices
      case 'receipt':
        return _BadgeConfig(
          label: 'سند قبض',
          textColor: AppColors.secondaryDark,
          backgroundColor: AppColors.secondaryLight.withOpacity(0.15),
          borderColor: AppColors.secondary.withOpacity(0.3),
        );
      case 'payment':
        return _BadgeConfig(
          label: 'سند صرف',
          textColor: AppColors.danger,
          backgroundColor: AppColors.dangerLight.withOpacity(0.15),
          borderColor: AppColors.danger.withOpacity(0.3),
        );
      case 'sale':
        return _BadgeConfig(
          label: 'مبيعات',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight.withOpacity(0.15),
          borderColor: AppColors.primary.withOpacity(0.3),
        );
      case 'purchase':
        return _BadgeConfig(
          label: 'مشتريات',
          textColor: AppColors.purple,
          backgroundColor: AppColors.purple.withOpacity(0.15),
          borderColor: AppColors.purple.withOpacity(0.3),
        );
      case 'sale_return':
        return _BadgeConfig(
          label: 'مردود مبيعات',
          textColor: AppColors.accent,
          backgroundColor: AppColors.accentLight.withOpacity(0.15),
          borderColor: AppColors.accent.withOpacity(0.3),
        );
      case 'purchase_return':
        return _BadgeConfig(
          label: 'مردود مشتريات',
          textColor: AppColors.danger,
          backgroundColor: AppColors.dangerLight.withOpacity(0.15),
          borderColor: AppColors.danger.withOpacity(0.3),
        );

      // Checks
      case 'under_collection':
        return _BadgeConfig(
          label: 'برسم التحصيل',
          textColor: AppColors.accent,
          backgroundColor: AppColors.accentLight.withOpacity(0.15),
          borderColor: AppColors.accent.withOpacity(0.3),
        );
      case 'collected':
        return _BadgeConfig(
          label: 'محصل بالبنك',
          textColor: AppColors.secondaryDark,
          backgroundColor: AppColors.secondaryLight.withOpacity(0.15),
          borderColor: AppColors.secondary.withOpacity(0.3),
        );
      case 'endorsed':
        return _BadgeConfig(
          label: 'مجير لمورد',
          textColor: AppColors.purple,
          backgroundColor: AppColors.purple.withOpacity(0.15),
          borderColor: AppColors.purple.withOpacity(0.3),
        );
      case 'bounced':
        return _BadgeConfig(
          label: 'مرتجع',
          textColor: AppColors.danger,
          backgroundColor: AppColors.dangerLight.withOpacity(0.15),
          borderColor: AppColors.danger.withOpacity(0.3),
        );
      case 'cancelled':
        return _BadgeConfig(
          label: 'ملغي',
          textColor: AppColors.lightTextSecondary,
          backgroundColor: Colors.grey.withOpacity(0.15),
          borderColor: Colors.grey.withOpacity(0.3),
        );

      // Quotations
      case 'draft':
        return _BadgeConfig(
          label: 'مسودة',
          textColor: AppColors.lightTextSecondary,
          backgroundColor: Colors.grey.withOpacity(0.15),
          borderColor: Colors.grey.withOpacity(0.3),
        );
      case 'sent':
        return _BadgeConfig(
          label: 'مرسل',
          textColor: AppColors.info,
          backgroundColor: AppColors.info.withOpacity(0.15),
          borderColor: AppColors.info.withOpacity(0.3),
        );
      case 'accepted':
        return _BadgeConfig(
          label: 'مقبول',
          textColor: AppColors.secondaryDark,
          backgroundColor: AppColors.secondaryLight.withOpacity(0.15),
          borderColor: AppColors.secondary.withOpacity(0.3),
        );
      case 'converted':
        return _BadgeConfig(
          label: 'تم التحويل لفاتورة',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight.withOpacity(0.15),
          borderColor: AppColors.primary.withOpacity(0.3),
        );

      // Stock transfers
      case 'transfer':
        return _BadgeConfig(
          label: 'مناقلة مستودعية',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight.withOpacity(0.15),
          borderColor: AppColors.primary.withOpacity(0.3),
        );
      case 'stock_in':
        return _BadgeConfig(
          label: 'إدخال مخزني',
          textColor: AppColors.secondaryDark,
          backgroundColor: AppColors.secondaryLight.withOpacity(0.15),
          borderColor: AppColors.secondary.withOpacity(0.3),
        );
      case 'stock_out':
        return _BadgeConfig(
          label: 'إخراج مخزني',
          textColor: AppColors.danger,
          backgroundColor: AppColors.dangerLight.withOpacity(0.15),
          borderColor: AppColors.danger.withOpacity(0.3),
        );
      case 'adjustment':
        return _BadgeConfig(
          label: 'تسوية جردية',
          textColor: AppColors.accent,
          backgroundColor: AppColors.accentLight.withOpacity(0.15),
          borderColor: AppColors.accent.withOpacity(0.3),
        );

      // Account Types
      case 'asset':
        return _BadgeConfig(
          label: 'أصول',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight.withOpacity(0.15),
          borderColor: AppColors.primary.withOpacity(0.3),
        );
      case 'liability':
        return _BadgeConfig(
          label: 'خصوم',
          textColor: AppColors.danger,
          backgroundColor: AppColors.dangerLight.withOpacity(0.15),
          borderColor: AppColors.danger.withOpacity(0.3),
        );
      case 'equity':
        return _BadgeConfig(
          label: 'حقوق ملكية',
          textColor: AppColors.purple,
          backgroundColor: AppColors.purple.withOpacity(0.15),
          borderColor: AppColors.purple.withOpacity(0.3),
        );
      case 'revenue':
        return _BadgeConfig(
          label: 'إيرادات',
          textColor: AppColors.secondaryDark,
          backgroundColor: AppColors.secondaryLight.withOpacity(0.15),
          borderColor: AppColors.secondary.withOpacity(0.3),
        );
      case 'expense':
        return _BadgeConfig(
          label: 'مصروفات',
          textColor: AppColors.accent,
          backgroundColor: AppColors.accentLight.withOpacity(0.15),
          borderColor: AppColors.accent.withOpacity(0.3),
        );

      default:
        return _BadgeConfig(
          label: status,
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight.withOpacity(0.15),
          borderColor: AppColors.primary.withOpacity(0.3),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  _BadgeConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
