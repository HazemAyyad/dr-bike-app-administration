import 'package:doctorbike/core/utils/localized_number.dart';
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

  /// Parses localized digits, decimal separators, and grouped amounts.
  static double parse(String? raw) => tryParseLocalizedAmount(raw) ?? 0;
}
