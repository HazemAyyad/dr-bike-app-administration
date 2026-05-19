/// Shekel display for debt ledger — symbol always after the number.
class LedgerFormat {
  static const String shekelSymbol = '₪';

  static String shekel(double amount, {int fractionDigits = 2}) {
    return '${amount.toStringAsFixed(fractionDigits)} $shekelSymbol';
  }

  static String shekel1(double amount) => shekel(amount, fractionDigits: 1);

  static String shekel2(double amount) => shekel(amount, fractionDigits: 2);

  /// e.g. «الرصيد 123.45 ₪»
  static String labeled(String label, double amount, {int fractionDigits = 2}) {
    return '$label ${amount.toStringAsFixed(fractionDigits)} $shekelSymbol';
  }
}
