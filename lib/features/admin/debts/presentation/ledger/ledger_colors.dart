import 'package:flutter/material.dart';

class LedgerColors {
  LedgerColors._();

  static const Color primaryBlue = Color(0xFF4A7FD4);
  static const Color cardBlue = Color(0xFFEEF4FF);
  static const Color takenGreen = Color(0xFF1B8A4A);
  static const Color givenRed = Color(0xFFC62828);
  static const Color neutral = Color(0xFF757575);

  /// موجب = أخضر، سالب = أحمر — بغضّ النظر عن نوع المعاملة (أخذت/أعطيت).
  static Color signedAmount(double value) {
    if (value > 0) return takenGreen;
    if (value < 0) return givenRed;
    return neutral;
  }
  static const Color background = Color(0xFFF8FAFF);
}
