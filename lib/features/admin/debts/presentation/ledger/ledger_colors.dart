import 'package:flutter/material.dart';

class LedgerColors {
  LedgerColors._();
  static Map<String, String> appearance = {};
  static String get receivableLabel => appearance['receivable_label'] ?? 'لك';
  static String get payableLabel => appearance['payable_label'] ?? 'عليك';
  static Color custom(String key, Color fallback) {
    final value = int.tryParse(appearance[key] ?? '', radix: 16);
    return value == null ? fallback : Color(0xFF000000 | value);
  }

  static Color get receipt => custom('receipt_color', takenGreen);
  static Color get payment => custom('payment_color', givenRed);
  static Color get invoice => custom('invoice_color', primaryBlue);
  static Color get receivable => custom('receivable_color', takenGreen);
  static Color get payable => custom('payable_color', givenRed);
  static Color get settled => custom('settled_color', neutral);

  static const Color primaryBlue = Color(0xFF4A7FD4);
  static const Color cardBlue = Color(0xFFEEF4FF);
  static const Color takenGreen = Color(0xFF1B8A4A);
  static const Color givenRed = Color(0xFFC62828);
  static const Color neutral = Color(0xFF757575);

  /// The ledger stores payables as positive and receivables as negative.
  static Color signedAmount(double value, {bool supplier = false}) {
    if (value.abs() < 0.005) return settled;
    return value > 0 ? payable : receivable;
  }

  static Color transaction(String type, {bool supplier = false}) =>
      type == 'taken' ? receipt : payment;

  static Color entry(String kind) {
    if (kind == 'receipt') return receipt;
    if (kind == 'payment') return payment;
    return invoice;
  }

  static const Color background = Color(0xFFF8FAFF);
}
