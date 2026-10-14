import 'package:flutter/services.dart';

import '../utils/localized_number.dart';

/// Converts localized digits before validating numeric keyboard input.
class LocalizedNumberInputFormatter extends TextInputFormatter {
  const LocalizedNumberInputFormatter({
    this.decimal = false,
    this.signed = false,
  });

  final bool decimal;
  final bool signed;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final text = normalizeNumericText(newValue.text);
    final pattern = decimal ? r'[0-9.,]*' : r'[0-9]*';
    final allowed = RegExp('${signed ? '-?' : ''}$pattern');
    final match = allowed.firstMatch(text);
    if (match == null || match.start != 0 || match.end != text.length) {
      return oldValue;
    }
    // Normalization replaces each character with one character, preserving
    // the selection when typing, pasting, or replacing text in the middle.
    return newValue.copyWith(text: text);
  }
}
