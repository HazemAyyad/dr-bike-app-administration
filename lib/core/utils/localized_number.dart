/// One-to-one normalization keeps text selections in numeric fields intact.
String normalizeNumericText(String input) {
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final code in input.codeUnits) {
    final character = String.fromCharCode(code);
    final arabicIndex = arabicDigits.indexOf(character);
    final persianIndex = persianDigits.indexOf(character);
    if (arabicIndex >= 0) {
      buffer.write(arabicIndex);
    } else if (persianIndex >= 0) {
      buffer.write(persianIndex);
    } else {
      buffer.write(character == '٫'
          ? '.'
          : character == '٬' || character == '،'
              ? ','
              : character);
    }
  }
  return buffer.toString();
}

/// Accepts decimal commas and existing grouped amount displays.
double? tryParseLocalizedAmount(String? input) {
  if (input == null) return null;
  var text = normalizeNumericText(input.replaceAll('٬', '')).trim();
  text = text.replaceAll(RegExp(r'\s|\u00a0'), '');
  if (!RegExp(r'^-?[0-9]+(?:[.,][0-9]+)*[.,]?$').hasMatch(text) &&
      !RegExp(r'^-?[.,][0-9]+$').hasMatch(text)) {
    return null;
  }
  if (text.contains(',') && text.contains('.')) {
    if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
      if (!RegExp(r'^-?[0-9]{1,3}(?:\.[0-9]{3})*,[0-9]*$').hasMatch(text)) {
        return null;
      }
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      if (!RegExp(r'^-?[0-9]{1,3}(?:,[0-9]{3})*\.[0-9]*$').hasMatch(text)) {
        return null;
      }
      text = text.replaceAll(',', '');
    }
  } else if (text.contains(',')) {
    final parts = text.split(',');
    if (parts.length == 2 && parts[1].length != 3) {
      text = text.replaceAll(',', '.');
    } else {
      if (!RegExp(r'^-?[0-9]{1,3}(?:,[0-9]{3})+$').hasMatch(text)) {
        return null;
      }
      text = text.replaceAll(',', '');
    }
  } else if ('.'.allMatches(text).length > 1) {
    return null;
  }
  final number = double.tryParse(text);
  return number != null && number.isFinite ? number : null;
}
