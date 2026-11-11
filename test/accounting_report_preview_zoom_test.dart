import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_pdf.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

import 'helpers/accounting_printing_stub.dart';

void main() {
  testWidgets('accounting previews zoom with buttons and a two-finger gesture',
      (tester) async {
    installAccountingPrintingStub();
    final document = AccountingReportDocument(
      kind: 'sales_accounting',
      title: 'تقرير مبيعات',
      from: '2026-11-01',
      to: '2026-11-11',
      currency: 'شيكل',
      columns: ['التاريخ', 'المبيعات'],
      rows: [
        ['2026-11-11', '100.00'],
        ['الإجمالي', '100.00'],
      ],
      summary: {},
      notes: [],
      selection: 'يومي',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child:
              AccountingReportPreview(snapshot: document, document: document),
        ),
      ),
    ));
    await settleAccountingPreview(tester);

    final image = find.descendant(
        of: find.byType(PdfPreview), matching: find.byType(Image));
    final fittedWidth = tester.getSize(image).width;
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('تكبير التقرير'));
    await tester.pumpAndSettle();
    expect(find.text('125%'), findsOneWidget);
    expect(tester.getSize(image).width, closeTo(fittedWidth * 1.25, .01));

    await tester.tap(find.byTooltip('تصغير التقرير'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تصغير التقرير'));
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsOneWidget);
    await tester.tap(find.text('75%'));
    await tester.pumpAndSettle();

    final pageCenter = tester.getTopLeft(image) + const Offset(220, 150);
    final left = await tester.startGesture(pageCenter - const Offset(40, 0));
    final right = await tester.startGesture(pageCenter + const Offset(40, 0));
    await left.moveBy(const Offset(-20, 0));
    await right.moveBy(const Offset(20, 0));
    await tester.pumpAndSettle();
    expect(find.text('150%'), findsOneWidget);
    await left.moveBy(const Offset(20, 0));
    await right.moveBy(const Offset(-20, 0));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    await left.up();
    await right.up();

    await tester.tap(find.text('فتح التقرير بملء الشاشة'));
    await settleAccountingPreview(tester);
    await tester.tap(find.byTooltip('تكبير التقرير'));
    await tester.pumpAndSettle();
    expect(find.text('125%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
