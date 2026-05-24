/// Amount display for debt ledger — symbol after the number.
class LedgerFormat {
  static const String shekelSymbol = '₪';

  static String symbolFor(String? currency) {
    switch (currency?.trim()) {
      case 'دولار':
        return '\$';
      case 'دينار':
        return 'د.أ';
      default:
        return shekelSymbol;
    }
  }

  static String money(double amount, {String currency = 'شيكل', int fractionDigits = 2}) {
    return '${amount.toStringAsFixed(fractionDigits)} ${symbolFor(currency)}';
  }

  static String shekel(double amount, {int fractionDigits = 2}) {
    return money(amount, currency: 'شيكل', fractionDigits: fractionDigits);
  }

  static String shekel1(double amount) => shekel(amount, fractionDigits: 1);

  static String shekel2(double amount) => shekel(amount, fractionDigits: 2);

  static String labeled(
    String label,
    double amount, {
    String currency = 'شيكل',
    int fractionDigits = 2,
  }) {
    return '$label ${money(amount, currency: currency, fractionDigits: fractionDigits)}';
  }
}
