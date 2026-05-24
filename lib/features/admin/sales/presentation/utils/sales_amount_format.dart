import 'package:intl/intl.dart';

/// Format sale amounts for display (handles large values like 10,000,000).
class SalesAmountFormat {
  static final NumberFormat _display = NumberFormat('#,##0.##');

  static String display(num value) {
    if (value.isNaN || value.isInfinite) return '0';
    return _display.format(value);
  }

  /// سعر بالشيكل (رمز ₪ بعد الرقم).
  static String displayShekel(num value) {
    if (value.isNaN || value.isInfinite || value <= 0) return '—';
    return '${display(value)} ₪';
  }

  /// Parse user input (allows commas / Arabic separators).
  static double parse(String? raw) {
    if (raw == null) return 0;
    final cleaned = raw
        .trim()
        .replaceAll(',', '')
        .replaceAll('،', '')
        .replaceAll(' ', '');
    return double.tryParse(cleaned) ?? 0;
  }
}
