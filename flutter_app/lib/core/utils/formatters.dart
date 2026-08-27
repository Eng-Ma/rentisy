import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  static String formatCurrency(dynamic amount, {String symbol = 'ر.س'}) {
    if (amount == null) return '0.00 $symbol';
    final val = amount is num ? amount : (double.tryParse(amount.toString()) ?? 0.0);
    return '${_currencyFormat.format(val)} $symbol';
  }

  static String formatNumber(dynamic number) {
    if (number == null) return '0';
    final val = number is num ? number : (num.tryParse(number.toString()) ?? 0);
    return _numberFormat.format(val);
  }

  static String formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is DateTime) return _dateFormat.format(date);
    try {
      final parsed = DateTime.parse(date.toString());
      return _dateFormat.format(parsed);
    } catch (_) {
      return date.toString();
    }
  }

  static String formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    if (dateTime is DateTime) return _dateTimeFormat.format(dateTime);
    try {
      final parsed = DateTime.parse(dateTime.toString());
      return _dateTimeFormat.format(parsed);
    } catch (_) {
      return dateTime.toString();
    }
  }
}
