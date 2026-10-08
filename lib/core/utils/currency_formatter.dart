import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 1,
  );

  /// Format double to Vietnamese currency format: "150.000 ₫"
  static String formatVND(double amount) {
    return _vndFormat.format(amount).trim();
  }

  /// Compact format for charts and stats: "150K ₫" or "1.5M ₫"
  static String formatCompact(double amount) {
    return _compactFormat.format(amount).trim();
  }

  /// Format date to "dd/MM/yyyy"
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Parse currency strings with mixed separators (., space) into a double
  static double parseAmount(String raw) {
    if (raw.trim().isEmpty) return 0.0;

    // Clean whitespace and currency symbols
    String cleaned = raw
        .replaceAll(RegExp(r'[VNDvndVNĐvnđ₫đ\s]'), '')
        .trim();

    // Check if contains both . and ,
    if (cleaned.contains('.') && cleaned.contains(',')) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      if (lastDot > lastComma) {
        // e.g. 1,500.50 -> comma is thousand, dot is decimal
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // e.g. 1.500,50 -> dot is thousand, comma is decimal
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleaned.contains('.')) {
      // Could be 150.000 (thousands) or 15.5 (decimal)
      final parts = cleaned.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        // Likely thousands separator: 150.000
        cleaned = cleaned.replaceAll('.', '');
      }
    } else if (cleaned.contains(',')) {
      // Could be 150,000 (thousands) or 15,5 (decimal)
      final parts = cleaned.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        // Likely thousands separator: 150,000
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // Decimal separator
        cleaned = cleaned.replaceAll(',', '.');
      }
    }

    return double.tryParse(cleaned) ?? 0.0;
  }
}
