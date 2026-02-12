import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format currency to Rupiah with thousands separator
  /// Example: 150000 -> Rp 150.000
  static String formatToRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format currency to compact format with K/M suffix
  /// Example: 150000 -> Rp 150k, 1500000 -> Rp 1.5M
  static String formatToCompact(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      if (millions == millions.roundToDouble()) {
        return 'Rp ${millions.toInt()}M';
      }
      return 'Rp ${millions.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      if (thousands == thousands.roundToDouble()) {
        return 'Rp ${thousands.toInt()}k';
      }
      return 'Rp ${thousands.toStringAsFixed(1)}k';
    } else {
      return 'Rp ${amount.toInt()}';
    }
  }

  /// Smart format: Uses compact for large numbers, full format for small numbers
  /// Example: 50000 -> Rp 50.000, 150000 -> Rp 150k
  static String formatSmart(double amount) {
    if (amount >= 100000) {
      return formatToCompact(amount);
    } else {
      return formatToRupiah(amount);
    }
  }

  /// Format currency to compact format WITHOUT Rp prefix
  /// Example: 500000 -> 500k, 2000000 -> 2jt
  static String formatToCompactNoPrefix(double amount) {
    if (amount >= 1000000) {
      // Format in millions (jt)
      final millions = amount / 1000000;
      if (millions == millions.roundToDouble()) {
        return '${millions.toInt()}jt';
      }
      return '${millions.toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      // Format in thousands (k)
      final thousands = amount / 1000;
      if (thousands == thousands.roundToDouble()) {
        return '${thousands.toInt()}k';
      }
      return '${thousands.toStringAsFixed(1)}k';
    } else {
      return amount.toInt().toString();
    }
  }

  
  /// Format currency (int version)
  static String format(int amount) {
    return formatToRupiah(amount.toDouble());
  }
}
