import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/accounting_reports/data/financial_accounting_api_service.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/controllers/financial_accounting_controller.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_reports_screen.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/financial_accounting_export.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/financial_accounting_screen.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:printing/printing.dart';
import 'helpers/accounting_printing_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('ReportAlmarai')
          ..addFont(
              rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    installAccountingPrintingStub();
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('opening filter is restored and exports keep the applied period',
      () async {
    final api = _FinancialApi();
    Map<String, dynamic>? saved;
    final c = FinancialAccountingController(
      service: FinancialAccountingApiService(api: api),
      type: 'expenses',
      savedFilters: {
        ..._filters,
        'include_opening': 1,
        'category_key': 'electricity',
        'box_id': '1'
      },
      persistFilters: (v) async {
        saved = v;
      },
    );
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.openingVisible, isTrue);
    expect(api.request!['category_key'], 'electricity');
    final csv = FinancialAccountingExport.buildCsv(c);
    expect(csv, contains('رصيد مدور'));
    expect(c.summary['period_total'], 40);
    c.changed(() {
      c.fromDate = DateTime(2026, 10, 1);
      c.toDate = DateTime(2026, 10, 31);
      c.includeOpening = false;
    });
    expect(c.pending, isTrue);
    expect(FinancialAccountingExport.buildCsv(c), csv);
    await c.load();
    expect(c.pending, isFalse);
    expect(c.openingVisible, isFalse);
    expect(saved!['from_date'], '2026-10-01');
    await c.setRemember(false);
    expect(saved, isNull);
  });

  test('income drilldown carries the displayed period and currency', () async {
    final c = FinancialAccountingController(
        service: FinancialAccountingApiService(api: _FinancialApi()),
        type: 'income',
        savedFilters: _filters);
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    c.changed(() => c.currency = 'دولار');
    final drilldown = c.expenseDrilldown(c.rows.last);
    expect(drilldown['currency'], 'شيكل');
    expect(drilldown['from_date'], '2026-09-01');
    expect(drilldown['category_key'], 'electricity');
    expect(drilldown['include_opening'], 0);
    expect(c.summaryCards['صافي الربح / الخسارة'], '460.00');
  });

  test('network errors clear stale balances and invalid ranges send no request',
      () async {
    final api = _FinancialApi();
    final c = FinancialAccountingController(
        service: FinancialAccountingApiService(api: api), type: 'expenses');
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    api.fail = true;
    await c.load();
    expect(c.report, isNull);
    expect(c.error, isNotNull);
    final calls = api.calls;
    c.toDate = c.fromDate.subtract(const Duration(days: 1));
    await c.load();
    expect(api.calls, calls);
  });

  testWidgets('section keeps all three reports available', (tester) async {
    await tester
        .pumpWidget(const GetMaterialApp(home: AccountingReportsScreen()));
    expect(find.text('إجمالي المبيعات'), findsOneWidget);
    expect(find.text('كشف حركات المصاريف'), findsOneWidget);
    expect(find.text('قائمة الدخل المفصّلة'), findsOneWidget);
  });

  for (final type in ['expenses', 'income']) {
    for (final width in [320.0, 1280.0]) {
      testWidgets('$type report and source details fit $width', (tester) async {
        tester.view.physicalSize = Size(width, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = _FinancialApi();
        final c = Get.put(
            FinancialAccountingController(
              service: FinancialAccountingApiService(api: api),
              type: type,
              savedFilters: {..._filters, 'include_opening': 1},
            ),
            tag: type);
        final boundary = GlobalKey();
        await tester.pumpWidget(GetMaterialApp(
          locale: const Locale('ar'),
          theme: ThemeData(fontFamily: 'ReportAlmarai'),
          home: RepaintBoundary(
              key: boundary, child: FinancialAccountingScreen(type: type)),
        ));
        await settleAccountingPreview(tester);
        expect(tester.takeException(), isNull);
        expect(c.rows, isNotEmpty);
        expect(find.byType(AccountingReportPreview), findsOneWidget);
        expect(find.byType(PdfPreview), findsOneWidget);
        if (width > 1000) {
          c.changed(() => c.currency = 'دولار');
          await tester.pump();
          expect(c.pending, isTrue);
          expect(tester.widget<IconButton>(accountingShareButton).onPressed,
              isNotNull);
          await tester.tap(accountingShareButton);
          await settleAccountingPreview(tester);
          expect(accountingPrinting.shareCalls, 1);
          expect(
              accountingPrinting.sharedBytes!.sublist(0, 4), [37, 80, 68, 70]);
          expect(FinancialAccountingExport.document(c).currency, 'شيكل');
          expect(c.exporting, isFalse);
          c.changed(() => c.currency = 'شيكل');
          await tester.pump();
        }
        await revealAccountingDetail(tester, find.text('تفاصيل الحركات'));
        await tester.tap(find.text('تفاصيل الحركات'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final evidence = Platform.environment['ACCOUNTING_REPORT_EVIDENCE_DIR'];
        if (evidence != null) {
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
            final image = await render.toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(evidence).create(recursive: true);
            await File('$evidence/$type-${width.toInt()}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
            if (width > 1000) {
              final bytes = await FinancialAccountingExport.buildPdf(c);
              expect(bytes.sublist(0, 4), [37, 80, 68, 70]);
              await File('$evidence/$type.pdf').writeAsBytes(bytes);
              await File('$evidence/$type.csv')
                  .writeAsString(FinancialAccountingExport.buildCsv(c));
            }
          });
        }
        if (type == 'expenses') {
          await revealAccountingDetail(tester, find.text('2026-09-01').last);
          await tester.tap(find.text('2026-09-01').last);
          await tester.pumpAndSettle();
          expect(api.detailCalls, 1);
          expect(find.text('تفاصيل الحركة'), findsOneWidget);
          expect(find.text('سند كهرباء تجريبي'), findsOneWidget);
          expect(find.text('الصندوق: الصندوق الرئيسي'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('إغلاق'));
          await tester.pumpAndSettle();
        }
      });
    }
  }
}

const _filters = {
  'from_date': '2026-09-01',
  'to_date': '2026-09-30',
  'currency': 'شيكل'
};

class _FinancialApi extends Fake implements ApiConsumer {
  bool fail = false;
  int calls = 0;
  int detailCalls = 0;
  Map<String, dynamic>? request;
  @override
  Future<dynamic> get(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters}) async {
    calls++;
    if (fail) throw Exception('تعذر الاتصال');
    Map<String, dynamic> result;
    if (path.contains('/movement/')) {
      detailCalls++;
      result = {
        'title': 'سند كهرباء تجريبي',
        'fields': [
          {'label': 'البيان', 'value': 'فاتورة كهرباء'}
        ],
        'lines': [
          {
            'account': 'الكهرباء',
            'debit': 50,
            'credit': 0,
            'box': 'الصندوق الرئيسي'
          }
        ]
      };
    } else {
      request = queryParameters;
      final expenses = path.endsWith('/expenses');
      result = {
        'filters': {
          'category_key': '',
          'box_id': '',
          ...queryParameters!,
          'include_opening': queryParameters['include_opening'] == 1
        },
        'currency': queryParameters['currency'],
        'summary': expenses
            ? {
                'opening_balance': 100,
                'debit': 50,
                'credit': 10,
                'period_total': 40,
                'closing_balance': 140,
                'movement_count': 2
              }
            : {
                'revenue': 1000,
                'sales_returns': 0,
                'net_revenue': 1000,
                'cost': 500,
                'gross_profit': 500,
                'expenses': 40,
                'net_profit': 460
              },
        'rows': expenses
            ? [
                {
                  'key': 'journal:1',
                  'detail_key': 'journal:1',
                  'date': '2026-09-01',
                  'entry_number': 'JRN-1',
                  'category_name': 'الكهرباء',
                  'description': 'فاتورة كهرباء',
                  'box_name': 'الصندوق الرئيسي',
                  'debit': 50,
                  'credit': 0,
                  'balance': 150,
                  'notes': 'سند صرف'
                },
                {
                  'key': 'journal:2',
                  'detail_key': 'journal:2',
                  'date': '2026-09-20',
                  'entry_number': 'JRN-2',
                  'category_name': 'الكهرباء',
                  'description': 'تصحيح مصروف',
                  'box_name': 'الصندوق الرئيسي',
                  'debit': 0,
                  'credit': 10,
                  'balance': 140,
                  'notes': ''
                },
              ]
            : [
                {
                  'key': 'sales',
                  'section': 'revenue',
                  'label': 'المبيعات',
                  'debit': 0,
                  'credit': 1000,
                  'balance': 1000
                },
                {
                  'key': 'cogs',
                  'section': 'cost',
                  'label': 'تكلفة المبيعات',
                  'debit': 500,
                  'credit': 0,
                  'balance': 500
                },
                {
                  'key': 'electricity',
                  'section': 'expense',
                  'label': 'الكهرباء',
                  'debit': 50,
                  'credit': 10,
                  'balance': 40
                },
              ],
        'categories': [
          {'key': 'electricity', 'name': 'الكهرباء'}
        ],
        'boxes': [
          {'key': '1', 'name': 'الصندوق الرئيسي'}
        ],
        'notes': [
          'الرصيد المدور لا يدخل في مصروف الفترة.',
          'القيود المعتمدة لا تتكرر مع مصدرها الأصلي.'
        ],
      };
    }
    return Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        data: {'status': 'success', 'data': result});
  }
}
