import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/accounting_reports/data/financial_accounting_api_service.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_pdf.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_preview.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/sales_profit_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/accounting_printing_stub.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets(
        'profit report preserves totals, filters and withdrawals at $width',
        (tester) async {
      installAccountingPrintingStub();
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _ProfitApi();
      await tester.pumpWidget(MaterialApp(
          home: SalesProfitReportScreen(
              service: FinancialAccountingApiService(api: api))));
      await settleAccountingPreview(tester);
      AccountingReportDocument mainDocument() => tester
          .widget<AccountingReportPreview>(
              find.byType(AccountingReportPreview).first)
          .document;
      final total = mainDocument();
      expect(total.columns, [
        'الرقم',
        'التاريخ',
        'نوع السند',
        'سعر التكلفة',
        'السعر',
        'الخصم في الفاتورة',
        'الربح',
        'نسبة الربح'
      ]);
      expect(total.rows.first, [
        'SAL-001',
        '2026-11-02',
        'فاتورة مبيعات',
        '60',
        '100.00',
        '10.00',
        '30.00',
        '50.00%'
      ]);
      expect(total.rows.last[6], '30.00');
      expect(api.calls, 1);
      final detailDropdown = find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<bool>);
      tester
          .widget<DropdownButtonFormField<bool>>(detailDropdown)
          .onChanged!(true);
      await settleAccountingPreview(tester);
      final detail = mainDocument();
      expect(detail.columns, [
        'الرقم',
        'التاريخ',
        'نوع السند',
        'رقم الصنف',
        'اسم الصنف',
        'الكمية',
        'بونص',
        'سعر التكلفة',
        'السعر',
        'الخصم',
        'الوحدة',
        'الربح',
        'نسبة الربح'
      ]);
      expect(detail.rows[1][6], '1');
      expect(detail.rows[1][11], '-20.00');
      expect(detail.rows.last[11], '30.00');
      expect(api.calls, 1);
      await _evidence(tester, [total, detail], width);

      await tester.ensureVisible(find.text('إظهار السحوبات غير المفوترة'));
      await tester.tap(find.text('إظهار السحوبات غير المفوترة'));
      await settleAccountingPreview(tester);
      // The applied document stays the same while its display changes locally.
      expect(mainDocument().summary, detail.summary);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('احتساب المرتجعات'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountingReportPreview), findsNothing);
      final sourceDropdown = find.byWidgetPredicate((widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'مصدر العملية');
      tester
          .widget<DropdownButtonFormField<String>>(sourceDropdown)
          .onChanged!('maintenance');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تطبيق وعرض التقرير'));
      await tester.tap(find.text('تطبيق وعرض التقرير'));
      await settleAccountingPreview(tester);
      expect(api.last!['source'], 'maintenance');
      expect(api.last!['include_returns'], 0);
      expect(api.last!['currency'], 'شيكل');
      expect(mainDocument().selection, contains('الصيانة'));
      expect(mainDocument().selection, contains('بدون المرتجعات'));
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _evidence(WidgetTester tester,
    List<AccountingReportDocument> documents, double width) async {
  final folder = Platform.environment['ACCOUNTING_REPORT_EVIDENCE_DIR'];
  if (folder == null || width != 320) return;
  await tester.runAsync(() async {
    await Directory(folder).create(recursive: true);
    for (final document in documents) {
      final bytes = await AccountingReportPdf.build(document);
      await File('$folder/${document.kind}.pdf').writeAsBytes(bytes);
    }
  });
}

class _ProfitApi extends Fake implements ApiConsumer {
  int calls = 0;
  Map<String, dynamic>? last;

  @override
  Future<dynamic> get(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters}) async {
    calls++;
    last = Map<String, dynamic>.of(queryParameters!);
    return Response(requestOptions: RequestOptions(path: path), data: {
      'status': 'success',
      'data': {
        'filters': {
          ...queryParameters,
          'include_returns': queryParameters['include_returns'] == 1
        },
        'summary': {
          'document_count': 1,
          'sales_total': 90,
          'cost_total': 60,
          'discount': 10,
          'profit': 30,
          'profit_percent': 50,
          'missing_cost_count': 0
        },
        'documents': [
          {
            'number': 'SAL-001',
            'date': '2026-11-02',
            'type': 'فاتورة مبيعات',
            'cost_total': 60,
            'sales_total': 90,
            'discount': 10,
            'profit': 30,
            'profit_percent': 50,
            'lines': [
              {
                'product_code': 'P001',
                'product': 'قطعة غيار أصلية للدراجة',
                'quantity': 2,
                'bonus': 0,
                'unit_cost': 20,
                'price': 50,
                'discount': 10,
                'unit': 'حبة',
                'profit': 50,
                'profit_percent': 125
              },
              {
                'product_code': 'P002',
                'product': 'بونص',
                'quantity': 1,
                'bonus': 1,
                'unit_cost': 20,
                'price': 0,
                'discount': 0,
                'unit': 'حبة',
                'profit': -20,
                'profit_percent': -100
              },
            ]
          }
        ],
        'withdrawals': [
          {
            'number': '9',
            'date': '2026-11-03',
            'type': 'سحب طلبية غير مفوترة',
            'product_code': 'P003',
            'product': 'قطعة غيار',
            'quantity': 1,
            'cost_total': 12,
            'note': 'طلبية قيد التوصيل'
          }
        ],
        'notes': [
          'الربح قبل المصاريف. تكلفة البونص ضمن الفاتورة. نسبة الربح على التكلفة.'
        ],
      }
    });
  }
}
