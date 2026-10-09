import 'package:doctorbike/features/admin/boxes/presentation/utils/box_adjustment_amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBoxAdjustmentAmount', () {
    test('parses Latin and localized decimal amounts', () {
      expect(parseBoxAdjustmentAmount('10.5'), 10.5);
      expect(parseBoxAdjustmentAmount('10,5'), 10.5);
      expect(parseBoxAdjustmentAmount('١٠٫٥'), 10.5);
      expect(parseBoxAdjustmentAmount('۱۲٫۵'), 12.5);
      expect(parseBoxAdjustmentAmount('١٬٢٥٠'), 1250);
    });

    test('rejects zero, negative, malformed, and non-finite amounts', () {
      expect(parseBoxAdjustmentAmount('0'), isNull);
      expect(parseBoxAdjustmentAmount('-10'), isNull);
      expect(parseBoxAdjustmentAmount('abc'), isNull);
      expect(parseBoxAdjustmentAmount('1,2,3'), isNull);
      expect(parseBoxAdjustmentAmount('NaN'), isNull);
      expect(parseBoxAdjustmentAmount('Infinity'), isNull);
    });
  });
}
