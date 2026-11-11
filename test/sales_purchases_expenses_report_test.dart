import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/accounting_reports/data/financial_accounting_api_service.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_preview.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/sales_purchases_expenses_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/accounting_printing_stub.dart';

void main() {
  testWidgets('switches from dated rows to the same totals without refetching',
      (tester) async {
    installAccountingPrintingStub();
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _ReportApi();
    await tester.pumpWidget(MaterialApp(
      home: SalesPurchasesExpensesReportScreen(
        service: FinancialAccountingApiService(api: api),
      ),
    ));
    await settleAccountingPreview(tester);

    final preview = find.byType(AccountingReportPreview);
    final daily = tester.widget<AccountingReportPreview>(preview).document;
    expect(daily.columns, ['التاريخ', 'المبيعات', 'المشتريات', 'المصاريف']);
    expect(daily.rows, [
      ['2026-09-01', '2,871.50', '2,029.07', '450.00'],
      ['الإجمالي', '2,871.50', '2,029.07', '450.00'],
    ]);

    await tester.tap(find.text('تفصيل يومي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إجمالي الفترة').last);
    await settleAccountingPreview(tester);

    final totals = tester.widget<AccountingReportPreview>(preview).document;
    expect(totals.columns.first, 'الفترة');
    expect(totals.rows, [
      ['2026-09-01 إلى 2026-09-30', '2,871.50', '2,029.07', '450.00'],
    ]);
    expect(api.calls, 1);
    expect(api.path, 'admin/accounting-reports/sales-purchases-expenses');
    expect(accountingPrinting.rasterCalls, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

class _ReportApi extends Fake implements ApiConsumer {
  int calls = 0;
  String? path;

  @override
  Future<dynamic> get(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters}) async {
    calls++;
    this.path = path;
    const totals = {'sales': 2871.50, 'purchases': 2029.07, 'expenses': 450};
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'status': 'success',
        'data': {
          'filters': {
            'from_date': '2026-09-01',
            'to_date': '2026-09-30',
            'currency': queryParameters!['currency'],
          },
          'rows': [
            {'date': '2026-09-01', ...totals},
          ],
          'summary': totals,
          'notes': <String>[],
        },
      },
    );
  }
}
