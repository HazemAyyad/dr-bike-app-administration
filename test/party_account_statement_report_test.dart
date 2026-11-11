import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/accounting_reports/data/financial_accounting_api_service.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_preview.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_pdf.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/party_account_statement_screen.dart';
import 'package:doctorbike/features/admin/widgets/unified_partner_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/accounting_printing_stub.dart';

void main() {
  testWidgets(
      'account statement uses the shared picker and prints accountant columns for either party',
      (tester) async {
    installAccountingPrintingStub();
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _StatementApi();
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
          home: PartyAccountStatementScreen(
        service: FinancialAccountingApiService(api: api),
      )),
    ));
    await tester.pumpAndSettle();
    final pickerFinder = find.byWidgetPredicate(
        (widget) => widget is UnifiedPartnerSelector<Map<String, dynamic>>);
    final picker = tester
        .widget<UnifiedPartnerSelector<Map<String, dynamic>>>(pickerFinder);
    expect(picker.customers.single['name'], 'زبون');
    expect(picker.sellers.single['name'], 'مورد');
    expect(api.lastRequest, isNull);

    await picker.onSelected(picker.customers.single, false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تطبيق وعرض الكشف'));
    await tester.tap(find.text('تطبيق وعرض الكشف'));
    await settleAccountingPreview(tester);
    final customer = tester
        .widget<AccountingReportPreview>(find.byType(AccountingReportPreview))
        .document;
    expect(customer.columns,
        ['الرقم', 'البيان', 'التاريخ', 'مدين', 'دائن', 'الرصيد', 'ملاحظات']);
    expect(customer.rows.first[1], 'الرصيد المدور');
    expect(customer.rows[1].first, 'SAL-001');
    expect(customer.rows[1].last, 'ملاحظة الفاتورة');
    expect(customer.rows.last[1], 'الشيكات الصادرة المرتجعة');
    expect(api.lastRequest!['person_type'], 'customer');
    expect(api.lastRequest!['currency'], 'شيكل');
    expect(api.lastRequest!['include_opening'], 1);
    await _saveEvidence(tester, customer, 'customer');

    final currentPicker = tester
        .widget<UnifiedPartnerSelector<Map<String, dynamic>>>(pickerFinder);
    await currentPicker.onSelected(currentPicker.sellers.single, true);
    await tester.pumpAndSettle();
    expect(find.byType(AccountingReportPreview), findsNothing);
    await tester.ensureVisible(find.text('احتساب الرصيد المدور'));
    await tester.tap(find.text('احتساب الرصيد المدور'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إظهار ملخص الشيكات المرتجعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق وعرض الكشف'));
    await settleAccountingPreview(tester);

    final supplier = tester
        .widget<AccountingReportPreview>(find.byType(AccountingReportPreview))
        .document;
    expect(supplier.rows.first[1], 'فاتورة مشتريات');
    expect(supplier.rows, hasLength(2));
    expect(supplier.rows.last[1], 'الرصيد');
    expect(supplier.rows.last[5], '-100.00');
    expect(api.lastRequest!['person_type'], 'seller');
    expect(api.lastRequest!['person_id'], 1);
    expect(api.lastRequest!['include_opening'], 0);
    expect(api.lastRequest!['include_returned_checks'], 0);
    await _saveEvidence(tester, supplier, 'supplier');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _saveEvidence(WidgetTester tester,
    AccountingReportDocument document, String party) async {
  final folder = Platform.environment['ACCOUNTING_REPORT_EVIDENCE_DIR'];
  if (folder == null) return;
  await tester.runAsync(() async {
    await Directory(folder).create(recursive: true);
    final bytes = await AccountingReportPdf.build(document);
    await File('$folder/account_statement_$party.pdf').writeAsBytes(bytes);
  });
}

class _StatementApi extends Fake implements ApiConsumer {
  Map<String, dynamic>? lastRequest;

  @override
  Future<dynamic> get(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters}) async {
    Map<String, dynamic> payload;
    if (path.endsWith('/people')) {
      payload = {
        'people': [
          {'id': 1, 'type': 'customer', 'name': 'زبون', 'phone': '0591'},
          {'id': 1, 'type': 'seller', 'name': 'مورد', 'phone': '0592'},
        ]
      };
    } else {
      lastRequest = Map<String, dynamic>.from(queryParameters!);
      final seller = queryParameters['person_type'] == 'seller';
      payload = {
        'filters': {
          ...queryParameters,
          'include_opening': queryParameters['include_opening'] == 1,
          'include_returned_checks':
              queryParameters['include_returned_checks'] == 1
        },
        'person': {'name': seller ? 'مورد' : 'زبون', 'phone': '0591'},
        'summary': {
          'opening_balance': 0,
          'debit': seller ? 0 : 100,
          'credit': seller ? 100 : 0,
          'closing_balance': seller ? -100 : 100
        },
        'rows': [
          {
            'number': seller ? '9' : 'SAL-001',
            'description': seller ? 'فاتورة مشتريات' : 'فاتورة مبيعات',
            'date': '2026-11-01',
            'debit': seller ? 0 : 100,
            'credit': seller ? 100 : 0,
            'balance': seller ? -100 : 100,
            'notes': 'ملاحظة الفاتورة'
          },
        ],
        'returned_checks': queryParameters['include_returned_checks'] == 1
            ? {'incoming': 0, 'outgoing': 0}
            : {},
        'notes': <String>[],
      };
    }
    return Response(
        requestOptions: RequestOptions(path: path),
        data: {'status': 'success', 'data': payload});
  }
}
