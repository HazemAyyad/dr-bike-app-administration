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

  /// Parse user input.
  ///
  /// يتعامل بذكاء مع الفواصل: الفاصلة قد تكون فاصلة عشرية (٨٣٫٥) أو فاصلة
  /// آلاف (٨٬٣٠٠). الخطأ القديم كان يحذف كل الفواصل فيتحول "83,00" إلى 8300.
  static double parse(String? raw) {
    if (raw == null) return 0;

    var s = _normalizeDigits(raw.trim());
    if (s.isEmpty) return 0;

    // توحيد رموز الفصل العربية إلى ASCII.
    s = s
        .replaceAll('٫', '.') // فاصلة عشرية عربية
        .replaceAll('٬', ',') // فاصلة آلاف عربية
        .replaceAll('،', ','); // فاصلة عربية عادية

    // إبقاء الأرقام والفواصل والإشارة فقط (إزالة رمز العملة والمسافات…).
    s = s.replaceAll(RegExp(r'[^0-9.,\-]'), '');
    if (s.isEmpty || s == '-') return 0;

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');

    if (hasComma && hasDot) {
      // الفاصل الأخير (الأقرب لليمين) هو الفاصل العشري.
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      final parts = s.split(',');
      // فاصلة واحدة يتبعها أقل من 3 أرقام = فاصلة عشرية (83,00 / 83,5).
      // غير ذلك (مجموعة من 3 أرقام أو أكثر من فاصلة) = فاصلة آلاف.
      if (parts.length == 2 && parts[1].length < 3) {
        s = '${parts[0]}.${parts[1]}';
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasDot) {
      // أكثر من نقطة = فواصل آلاف بالنمط الأوروبي (1.234.567).
      if ('.'.allMatches(s).length > 1) {
        s = s.replaceAll('.', '');
      }
    }

    return double.tryParse(s) ?? 0;
  }

  /// تحويل الأرقام العربية/الفارسية إلى أرقام لاتينية.
  static String _normalizeDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final ai = arabicIndic.indexOf(ch);
      if (ai != -1) {
        buffer.write(ai);
        continue;
      }
      final ea = easternArabic.indexOf(ch);
      if (ea != -1) {
        buffer.write(ea);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }
}
