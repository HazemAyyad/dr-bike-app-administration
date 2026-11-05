import 'package:flutter/material.dart';

class LedgerColors {
  LedgerColors._();

  static const Color primaryBlue = Color(0xFF4A7FD4);
  static const Color cardBlue = Color(0xFFEEF4FF);
  static const Color takenGreen = Color(0xFF1B8A4A);
  static const Color givenRed = Color(0xFFC62828);
  static const Color neutral = Color(0xFF757575);

  /// The ledger stores payables as positive and receivables as negative.
  static Color signedAmount(double value, {bool supplier = false}) {
    if (value.abs() < 0.005) return neutral;
    return value > 0 ? givenRed : takenGreen;
  }

  static Color transaction(String type, {bool supplier = false}) =>
      type == 'taken' ? takenGreen : givenRed;

  static Color entry(String kind) {
    if (kind == 'receipt') return takenGreen;
    if (kind == 'payment') return givenRed;
    return primaryBlue;
  }

  static const Color background = Color(0xFFF8FAFF);
}
