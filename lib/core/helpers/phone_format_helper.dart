/// تنسيق أرقام الهاتف للـ API (+972 5xxxxxxxx) وللاتصال (tel:).
class PhoneFormatHelper {
  static const String defaultDial = '+972';

  /// صيغة API: `+972 599999999` أو `+970 599999999`
  /// إذا الرقم بدون مقدمة دولة تُضاف [defaultDial] تلقائياً (افتراضي +972).
  static String forApi(String raw, {String defaultDialCode = defaultDial}) {
    var s = raw.trim();
    if (s.isEmpty) return '';

    // صيغة صحيحة جاهزة
    if (RegExp(r'^\+\d{3} \d{9}$').hasMatch(s)) {
      return s;
    }

    var digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    var dial = defaultDialCode;
    if (digits.startsWith('972')) {
      dial = '+972';
      digits = digits.substring(3);
    } else if (digits.startsWith('970')) {
      dial = '+970';
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // أحياناً يبقى كود الدولة داخل الجزء المحلي
    if (digits.length > 9) {
      if (digits.startsWith('972')) {
        dial = '+972';
        digits = digits.substring(3);
      } else if (digits.startsWith('970')) {
        dial = '+970';
        digits = digits.substring(3);
      }
    }

    if (digits.length > 9) {
      digits = digits.substring(digits.length - 9);
    }

    return '$dial $digits';
  }

  /// لـ url_launcher tel:
  static String forDialer(String raw) {
    final formatted = forApi(raw);
    if (formatted.isEmpty) return '';
    return formatted.replaceAll(' ', '');
  }

  static bool isValidApiPhone(String phone) {
    return RegExp(r'^\+\d{3} \d{9}$').hasMatch(phone.trim());
  }
}
