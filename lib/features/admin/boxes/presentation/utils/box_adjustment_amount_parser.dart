double? parseBoxAdjustmentAmount(String input) {
  var normalized = input.trim();
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  const persianDigits = '۰۱۲۳۴۵۶۷۸۹';

  for (var index = 0; index < 10; index++) {
    normalized = normalized
        .replaceAll(arabicDigits[index], '$index')
        .replaceAll(persianDigits[index], '$index');
  }

  normalized = normalized
      .replaceAll(' ', '')
      .replaceAll('\u00A0', '')
      .replaceAll('٬', '')
      .replaceAll('٫', '.')
      .replaceAll('،', ',');

  if (normalized.contains(',')) {
    if (normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '');
    } else if (','.allMatches(normalized).length == 1) {
      normalized = normalized.replaceAll(',', '.');
    } else {
      return null;
    }
  }

  final amount = double.tryParse(normalized);
  if (amount == null || !amount.isFinite || amount <= 0) return null;
  return amount;
}
