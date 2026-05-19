/// Payment/box log notes are capped at 500 characters on the API.
class BoxLogNoteFormat {
  static const int apiMaxLength = 500;
  static const int _maxLinesListed = 4;

  static String clamp(String note) {
    if (note.length <= apiMaxLength) {
      return note;
    }
    if (apiMaxLength <= 1) {
      return '';
    }
    return '${note.substring(0, apiMaxLength - 1)}…';
  }

  /// Compact note for instant-sale payment (قبض).
  static String instantSaleReceive({
    required List<String> lineLabels,
    required String amount,
  }) {
    const prefix = 'قبض — بيع فوري';
    final amountPart = 'مبلغ: $amount';

    if (lineLabels.isEmpty) {
      return clamp('$prefix | $amountPart');
    }

    if (lineLabels.length > _maxLinesListed) {
      final compact = '$prefix | ${lineLabels.length} منتج | $amountPart';
      if (compact.length <= apiMaxLength) {
        return compact;
      }
    }

    final joined = lineLabels.join(' | ');
    final full = '$prefix | $joined | $amountPart';
    if (full.length <= apiMaxLength) {
      return full;
    }

    if (lineLabels.length > 2) {
      final head = lineLabels.take(2).join(' | ');
      final rest = lineLabels.length - 2;
      final partial = '$prefix | $head | +$rest أخرى | $amountPart';
      if (partial.length <= apiMaxLength) {
        return partial;
      }
    }

    return clamp('$prefix | ${lineLabels.length} منتج | $amountPart');
  }
}
