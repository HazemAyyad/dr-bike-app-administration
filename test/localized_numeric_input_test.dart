import 'package:doctorbike/core/helpers/localized_number_input_formatter.dart';
import 'package:doctorbike/core/utils/localized_number.dart';
import 'package:doctorbike/features/admin/sales/data/models/daily_session_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/utils/sales_amount_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prices, discounts and payments retain their decimal value', () {
    for (final input in ['١٢٫٥', '۱۲٫۵', '12.5', '12,5', '١٢،٥']) {
      expect(tryParseLocalizedAmount(input), 12.5);
      expect(SalesAmountFormat.parse(input), 12.5);
      expect(DailyCashCountRow.cleanRequestAmount(input), '12.5');
    }
    final total =
        SalesAmountFormat.parse('١٢٫٥') * 2 - SalesAmountFormat.parse('٠٫٧٥');
    expect(total, 24.25);
    expect(total - SalesAmountFormat.parse('١٠٫٥'), 13.75);
  });

  test('grouped amounts still parse without multiplying the payment', () {
    for (final input in ['1,250.75', '١٬٢٥٠٫٧٥', '1.250,75']) {
      expect(tryParseLocalizedAmount(input), 1250.75);
    }
    expect(tryParseLocalizedAmount('10,000'), 10000);
    expect(tryParseLocalizedAmount('0.125'), 0.125);
    for (final input in ['abc', '1.2.3', '1,2,3', 'NaN', 'Infinity']) {
      expect(tryParseLocalizedAmount(input), isNull);
    }
  });

  test('editing in the middle keeps the caret and integer quantities', () {
    const formatter = LocalizedNumberInputFormatter();
    const input = TextEditingValue(
      text: '1٢3',
      selection: TextSelection.collapsed(offset: 2),
    );
    final normalized =
        formatter.formatEditUpdate(TextEditingValue.empty, input);
    expect(normalized.text, '123');
    expect(normalized.selection.baseOffset, 2);
    expect(
        formatter.formatEditUpdate(
            normalized, const TextEditingValue(text: '1.5')),
        normalized);
  });

  testWidgets('typing and pasting update the amount seen by calculations',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var paid = 0.0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: const [
          LocalizedNumberInputFormatter(decimal: true),
        ],
        onChanged: (value) => paid = SalesAmountFormat.parse(value),
      )),
    ));
    await tester.enterText(find.byType(TextField), '١٢٫٥');
    expect(controller.text, '12.5');
    expect(paid, 12.5);
    await tester.enterText(find.byType(TextField), '۱۲٫۷۵');
    expect(controller.text, '12.75');
    expect(paid, 12.75);
    await tester.enterText(find.byType(TextField), '١٬٢٥٠٫٧٥');
    expect(controller.text, '1,250.75');
    expect(paid, 1250.75);
    await tester.enterText(find.byType(TextField), '12,5');
    expect(paid, 12.5);
  });
}
