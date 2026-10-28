import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/accounting_reports/data/sales_accounting_api_service.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/controllers/sales_accounting_controller.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/sales_accounting_export.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/sales_accounting_screen.dart';
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
    final fonts = FontLoader('AccountingAlmarai')
      ..addFont(rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf'));
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    installAccountingPrintingStub();
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('restores filters and exports only the applied snapshot', () async {
    final api = _ReportApi();
    Map<String, dynamic>? saved;
    final c = SalesAccountingController(
      service: SalesAccountingApiService(api: api),
      savedFilters: {
        'from_date': '2026-01-01',
        'to_date': '2026-10-25',
        'group_by': 'month',
        'include_returns': 1,
        'person_key': '',
        'sort': 'label',
      },
      persistFilters: (value) async {
        saved = value;
      },
    );
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.remember, isTrue);
    expect(api.request!['group_by'], 'month');
    expect(api.request!['include_returns'], 1);
    expect(saved!['from_date'], '2026-01-01');
    expect(c.returnsVisible, isTrue);
    final before = SalesAccountingExport.buildCsv(c);
    c.changed(() {
      c.groupBy = 'day';
      c.includeReturns = false;
    });
    expect(c.hasPendingFilters, isTrue);
    expect(c.returnsVisible, isTrue);
    expect(SalesAccountingExport.buildCsv(c), before);
    await c.load();
    expect(c.hasPendingFilters, isFalse);
    expect(c.returnsVisible, isFalse);
    expect(c.columns, isNot(contains('المرتجعات')));
    await c.setRemember(false);
    expect(saved, isNull);
  });

  test('failed refresh clears stale figures and invalid dates send no request',
      () async {
    final api = _ReportApi();
    final c =
        SalesAccountingController(service: SalesAccountingApiService(api: api));
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.report, isNotNull);
    api.fail = true;
    await c.load();
    expect(c.report, isNull);
    expect(c.error, contains('غير متاح'));
    final count = api.calls;
    c.toDate = c.fromDate.subtract(const Duration(days: 1));
    await c.load();
    expect(api.calls, count);
    expect(c.isLoading, isFalse);
  });

  test('column choices persist locally and apply with the report snapshot',
      () async {
    final api = _ReportApi();
    Map<String, dynamic>? saved;
    final c = SalesAccountingController(
      service: SalesAccountingApiService(api: api),
      savedFilters: {
        'include_returns': 1,
        'columns': [
          'label',
          'returns_total',
          'net_sales',
          'return_discount',
          'unknown'
        ],
      },
      persistFilters: (value) async => saved = value,
    );
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(api.request!.containsKey('columns'), isFalse);
    expect(c.columnIds, ['label', 'returns_total', 'net_sales']);
    expect(c.columns, ['الزبون / الطرف', 'المرتجعات', 'صافي المبيعات']);
    expect(c.cells(c.rows.first), ['زبون تجريبي', '90.00', '810.00']);
    expect(c.cells(c.summary, total: true), ['الإجمالي', '120.00', '780.00']);
    expect(saved!['columns'], ['label', 'returns_total', 'net_sales']);
    final csv = SalesAccountingExport.buildCsv(c);
    c.selectColumn('returns_total', false);
    expect(c.hasPendingFilters, isTrue);
    expect(SalesAccountingExport.buildCsv(c), csv);
    await c.load();
    expect(c.hasPendingFilters, isFalse);
    expect(c.columns, ['الزبون / الطرف', 'صافي المبيعات']);
    expect(SalesAccountingExport.document(c).rows.first,
        ['زبون تجريبي', '810.00']);
    expect(SalesAccountingExport.buildCsv(c), isNot(contains('"المرتجعات"')));
    await c.setRemember(true);
    expect(saved!['columns'], ['label', 'net_sales']);
    final restored = SalesAccountingController(
        service: SalesAccountingApiService(api: _ReportApi()),
        savedFilters: saved);
    restored.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(restored.columnIds, ['label', 'net_sales']);
    await c.setRemember(false);
    expect(saved, isNull);
  });

  test(
      'every grouping projects matching cells and widths for one, two, three or all columns',
      () async {
    for (final group in SalesAccountingController.groups.keys) {
      final c = SalesAccountingController(
          service: SalesAccountingApiService(api: _ReportApi()),
          savedFilters: {'group_by': group, 'include_returns': 1});
      c.onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.columns, isNot(contains('خصم المرتجعات')));
      expect(c.availableColumns.keys, isNot(contains('return_discount')));
      for (final ids in [
        ['label'],
        ['label', 'net_sales'],
        ['gross_sales', 'returns_total', 'net_sales'],
      ]) {
        c.selectAllColumns();
        for (final id in c.availableColumns.keys) {
          if (!ids.contains(id)) c.selectColumn(id, false);
        }
        await c.load();
        expect(c.columnIds, ids);
        final doc = SalesAccountingExport.document(c);
        expect(doc.columns, hasLength(ids.length));
        expect(c.columnWidths, hasLength(ids.length));
        for (final row in doc.rows) {
          expect(row, hasLength(ids.length));
        }
        if (ids.length == 3) {
          expect(doc.rows.first, ['1000.00', '90.00', '810.00']);
          expect(doc.rows.last, ['1000.00', '120.00', '780.00']);
        }
      }
      c.selectAllColumns();
      await c.load();
      expect(c.columnIds.length, c.availableColumns.length);
      expect(c.hasPendingFilters, isFalse);
    }
  });

  test(
      'the last column stays selected and hidden-only selections recover across layouts',
      () async {
    final c = SalesAccountingController(
        service: SalesAccountingApiService(api: _ReportApi()),
        savedFilters: {
          'group_by': 'month',
          'columns': ['sequence']
        });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    c.selectColumn('sequence', false);
    expect(c.selectedColumnCount, 1);
    expect(c.cells(c.summary, total: true), ['الإجمالي']);
    c.selectGroup('day');
    expect(c.selectedColumnCount, 1);
    await c.load();
    expect(c.columnIds, ['label']);
    c.selectReturns(true);
    c.selectColumn('returns_total', true);
    c.selectColumn('label', false);
    c.selectReturns(false);
    expect(c.isColumnSelected('label'), isTrue);
    await c.load();
    expect(c.columnIds, ['label']);
  });

  test('custom column layouts generate PDFs with two, three and all columns',
      () async {
    final c = SalesAccountingController(
        service: SalesAccountingApiService(api: _ReportApi()),
        savedFilters: {'group_by': 'month', 'include_returns': 1});
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    for (final layout in ['two', 'three', 'all']) {
      c.selectAllColumns();
      if (layout != 'all') {
        final ids = [
          'label',
          'net_sales',
          if (layout == 'three') 'returns_total'
        ];
        for (final id in c.availableColumns.keys) {
          if (!ids.contains(id)) c.selectColumn(id, false);
        }
      }
      await c.load();
      final bytes = await SalesAccountingExport.buildPdf(c);
      expect(bytes.sublist(0, 4), [37, 80, 68, 70]);
      final evidence = Platform.environment['ACCOUNTING_REPORT_EVIDENCE_DIR'];
      if (evidence != null) {
        await Directory(evidence).create(recursive: true);
        await File('$evidence/columns-$layout.pdf').writeAsBytes(bytes);
      }
    }
  });

  for (final width in [320.0, 1280.0]) {
    testWidgets('column picker applies a subset and restores all at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = Get.put(SalesAccountingController(
          service: SalesAccountingApiService(api: _ReportApi()),
          savedFilters: {
            'columns': ['label', 'sales_total', 'sales_discount']
          }));
      await tester
          .pumpWidget(const GetMaterialApp(home: SalesAccountingScreen()));
      await tester.pump();
      final picker = find.byKey(const ValueKey('sales-report-column-picker'));
      await revealAccountingDetail(tester, picker);
      await tester.tap(find.text('أعمدة التقرير'));
      await tester.pumpAndSettle();
      final discount =
          find.byKey(const ValueKey('sales-report-column-sales_discount'));
      await revealAccountingDetail(tester, discount);
      await tester.tap(discount);
      await tester.pump();
      expect(c.selectedColumnCount, 2);
      expect(c.columnIds, hasLength(3));
      final apply = find.text('تطبيق وعرض التقرير');
      await revealAccountingDetail(tester, apply);
      await tester.tap(apply);
      await settleAccountingPreview(tester);
      expect(c.columnIds, ['label', 'sales_total']);
      expect(SalesAccountingExport.document(c).columns,
          ['الزبون / الطرف', 'المبيعات بعد الخصم']);
      final all = find.text('عرض كل الأعمدة');
      await revealAccountingDetail(tester, all);
      await tester.tap(all);
      await tester.pump();
      expect(c.selectedColumnCount, c.availableColumns.length);
      expect(tester.takeException(), isNull);
    });
  }

  test('CSV keeps negative amounts numeric and protects account names',
      () async {
    final c = SalesAccountingController(
        service: SalesAccountingApiService(api: _ReportApi()));
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    (c.report!['rows'] as List).first['label'] = '=SUM(A1:A2)';
    final csv = SalesAccountingExport.buildCsv(c);
    expect(csv, contains('"\'=SUM(A1:A2)"'));
    c.report!['filters']['include_returns'] = true;
    expect(SalesAccountingExport.buildCsv(c), contains('"-30.00"'));
  });

  test('monthly layout has month rows and restores currency and value limits',
      () async {
    final api = _ReportApi();
    final c = SalesAccountingController(
        service: SalesAccountingApiService(api: api),
        savedFilters: {
          'group_by': 'month',
          'sort': 'label',
          'currency': 'دولار',
          'min_amount': 100,
          'max_amount': 200,
        });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(api.request!['currency'], 'دولار');
    expect(api.request!['min_amount'], 100);
    expect(c.hasPendingFilters, isFalse);
    expect(
        c.columns.take(4), ['م', 'الشهر / السنة', 'المبيعات', 'خصم المبيعات']);
    expect(c.cells(c.rows.first).take(2), ['1', '2026-01']);
    expect(SalesAccountingExport.document(c).columns, c.columns);
    expect(SalesAccountingExport.document(c).title, 'تقرير مبيعات');
    expect(c.cells(c.summary, total: true).take(2), ['', 'الإجمالي']);
    c.selectGroup('day');
    expect(c.sort, 'label');
    expect(c.columns,
        contains('الشهر / السنة')); // Applied layout stays until reload.
    await c.load();
    expect(c.columns, isNot(contains('الشهر / السنة')));
    final calls = api.calls;
    c.minAmount = '٢٠١';
    await c.load();
    expect(api.calls, calls);
    expect(c.error, isNotNull);
    c.minAmount = 'abc';
    expect(c.hasPendingFilters, isTrue);
  });

  test(
      'employee and other-currency choices persist without combining currency totals',
      () async {
    final api = _ReportApi();
    final c = SalesAccountingController(
        service: SalesAccountingApiService(api: api),
        savedFilters: {
          'group_by': 'month',
          'include_other_currencies': 1,
          'representative_id': '7',
        });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(api.request!['representative_id'], '7');
    expect(api.request!['include_other_currencies'], 1);
    expect(c.hasPendingFilters, isFalse);
    expect(c.currencyReports, hasLength(2));
    final docs = SalesAccountingExport.documents(c);
    expect(docs.map((d) => d.currency), ['شيكل', 'دولار']);
    expect(docs.last.summary['المبيعات بعد الخصم'], '50.00');
    expect(docs.last.rows.first[0], '1');
    expect(docs.first.selection, contains('موظف تجريبي'));
    final csv = SalesAccountingExport.buildCsv(c);
    expect(csv, contains('العملة: شيكل'));
    expect(csv, contains('العملة: دولار'));
    c.changed(() {
      c.includeOtherCurrencies = false;
      c.representativeId = '';
    });
    expect(c.hasPendingFilters, isTrue);
    expect(SalesAccountingExport.buildCsv(c), csv);
    await c.load();
    expect(c.currencyReports, hasLength(1));
  });

  test(
      'long currency statements generate a combined PDF without losing sections',
      () async {
    final c = SalesAccountingController(
        service: SalesAccountingApiService(api: _ReportApi()),
        savedFilters: {
          'group_by': 'customer',
          'include_other_currencies': 1,
        });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    final first = (c.report!['currency_reports'] as List).first as Map;
    final original =
        Map<String, dynamic>.from((first['rows'] as List).first as Map);
    first['rows'] = [
      for (var i = 0; i < 180; i++)
        {...original, 'key': 'customer:$i', 'label': 'زبون تجريبي ${i + 1}'}
    ];
    final bytes = await SalesAccountingExport.buildPdf(c);
    expect(bytes.sublist(0, 4), [37, 80, 68, 70]);
    expect(SalesAccountingExport.documents(c), hasLength(2));
    final evidence = Platform.environment['ACCOUNTING_REPORT_EVIDENCE_DIR'];
    if (evidence != null) {
      await Directory(evidence).create(recursive: true);
      await File('$evidence/long-currencies.pdf').writeAsBytes(bytes);
    }
  });

  testWidgets('visible share works for the displayed report and in fullscreen',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = Get.put(SalesAccountingController(
        service: SalesAccountingApiService(api: _ReportApi())));
    await tester
        .pumpWidget(const GetMaterialApp(home: SalesAccountingScreen()));
    await tester.pump();
    await revealAccountingDetail(tester, find.text('فتح التقرير بملء الشاشة'));
    await settleAccountingPreview(tester);
    c.changed(() => c.currency = 'دولار');
    await tester.pump();
    expect(c.hasPendingFilters, isTrue);
    expect(
        tester.widget<IconButton>(accountingShareButton).onPressed, isNotNull);
    c.changed(() => c.isExporting = true);
    await tester.pump();
    expect(tester.widget<IconButton>(accountingShareButton).onPressed, isNull);
    c.changed(() => c.isExporting = false);
    await tester.pump();
    await tester.tap(accountingShareButton);
    await settleAccountingPreview(tester);
    expect(accountingPrinting.shareCalls, 1);
    expect(accountingPrinting.sharedBytes!.sublist(0, 4), [37, 80, 68, 70]);
    expect(SalesAccountingExport.document(c).currency, 'شيكل');
    expect(c.isExporting, isFalse);
    await revealAccountingDetail(tester, find.text('فتح التقرير بملء الشاشة'));
    await tester.tap(find.text('فتح التقرير بملء الشاشة'));
    await settleAccountingPreview(tester);
    expect(accountingShareButton, findsOneWidget);
    await tester.tap(accountingShareButton);
    await settleAccountingPreview(tester);
    expect(accountingPrinting.shareCalls, 2);
    expect(accountingPrinting.sharedFilename, 'sales_accounting.pdf');
    expect(tester.takeException(), isNull);
  });

  for (final mode in ['customer', 'month', 'multi']) {
    final grouping = mode == 'multi' ? 'month' : mode;
    for (final size in [const Size(320, 740), const Size(1280, 900)]) {
      testWidgets('$mode accounting report is readable at ${size.width}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = Get.put(SalesAccountingController(
          service: SalesAccountingApiService(api: _ReportApi()),
          savedFilters: {
            'from_date': '2026-01-01',
            'to_date': '2026-10-25',
            'group_by': grouping,
            'include_returns': 1,
            'sort': 'sales_desc',
            'include_other_currencies': mode == 'multi' ? 1 : 0,
          },
        ));
        final boundary = GlobalKey();
        await tester.pumpWidget(GetMaterialApp(
          locale: const Locale('ar'),
          theme: ThemeData(fontFamily: 'AccountingAlmarai'),
          home: RepaintBoundary(
              key: boundary, child: const SalesAccountingScreen()),
        ));
        await tester.pump();
        expect(find.text('تقارير محاسبية'), findsOneWidget);
        expect(find.text('تذكّر خياراتي'), findsOneWidget);
        expect(c.rows, hasLength(2));
        await revealAccountingDetail(
            tester, find.text('فتح التقرير بملء الشاشة'));
        await settleAccountingPreview(tester);
        expect(find.byType(AccountingReportPreview), findsOneWidget);
        expect(find.byType(PdfPreview), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (grouping == 'month') {
          expect(c.columns, contains('الشهر / السنة'));
          expect(c.columns, isNot(contains('الزبون / الطرف')));
        }
        await revealAccountingDetail(tester, find.text('تفاصيل الحركات'));
        await tester.tap(find.text('تفاصيل الحركات'));
        await tester.pumpAndSettle();
        expect(find.text('الإجمالي'), findsNWidgets(mode == 'multi' ? 2 : 1));
        expect(tester.takeException(), isNull);

        final evidence = Platform.environment['ACCOUNTING_REPORT_EVIDENCE_DIR'];
        if (evidence != null) {
          final render = boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage(pixelRatio: 1);
            final bytes =
                (await image.toByteData(format: ui.ImageByteFormat.png))!;
            final dir = Directory(evidence);
            await dir.create(recursive: true);
            await File('${dir.path}/accounting-$mode-${size.width.toInt()}.png')
                .writeAsBytes(bytes.buffer.asUint8List());
            image.dispose();
            if (size.width > 1000) {
              final pdf = await SalesAccountingExport.buildPdf(c);
              expect(pdf.sublist(0, 4), [37, 80, 68, 70]);
              await File('${dir.path}/accounting-$mode.pdf').writeAsBytes(pdf);
              await File('${dir.path}/accounting-$mode.csv')
                  .writeAsString(SalesAccountingExport.buildCsv(c));
            }
          });
        }
      });
    }
  }
}

class _ReportApi extends Fake implements ApiConsumer {
  Map<String, dynamic>? request;
  bool fail = false;
  int calls = 0;

  @override
  Future<dynamic> get(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters}) async {
    request = Map<String, dynamic>.from(queryParameters!);
    calls++;
    if (fail) throw Exception('الخادم غير متاح');
    final row = <String, dynamic>{
      'key': request!['group_by'] == 'month' ? '2026-01' : 'customer:1',
      'label': request!['group_by'] == 'month' ? '2026-01' : 'زبون تجريبي',
      'invoice_count': 2,
      'gross_sales': 1000,
      'sales_discount': 100,
      'sales_total': 900,
      'returns_total': 90,
      'return_discount': 0,
      'net_sales': 810,
      'sales_share': 100,
      'return_rate': 10,
    };
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: {
        'status': 'success',
        'data': {
          'filters': {
            ...request!,
            'include_returns': request!['include_returns'] == 1,
            'cash_only': request!['cash_only'] == 1,
            'include_other_currencies':
                request!['include_other_currencies'] == 1,
          },
          'summary': {
            ...row,
            'row_count': 2,
            'returns_total': 120,
            'return_discount': null,
            'net_sales': 780,
            'return_rate': 13.33,
          },
          'rows': [
            row,
            {
              ...row,
              'key': request!['group_by'] == 'month' ? '2026-02' : 'customer:2',
              'label': request!['group_by'] == 'month'
                  ? '2026-02'
                  : 'مرتجع من فترة سابقة',
              'gross_sales': 0,
              'invoice_count': 0,
              'sales_discount': 0,
              'sales_total': 0,
              'returns_total': 30,
              'return_discount': null,
              'net_sales': -30,
              'sales_share': 0,
              'return_rate': null,
            }
          ],
          'currency': request!['currency'] ?? 'شيكل',
          'people': [
            {'key': 'customer:1', 'name': 'زبون تجريبي', 'type': 'customer'}
          ],
          'representatives': [
            {'key': '7', 'name': 'موظف تجريبي'}
          ],
          'notes': ['نسبة المرتجعات من مبيعات الصف نفسه.'],
        }
      },
    );
    final report = response.data['data'] as Map<String, dynamic>;
    report['currency_reports'] = [
      {
        'currency': report['currency'],
        'rows': report['rows'],
        'summary': report['summary']
      },
      if (request!['include_other_currencies'] == 1)
        {
          'currency': 'دولار',
          'rows': [
            {
              ...row,
              'gross_sales': 50,
              'sales_discount': 0,
              'sales_total': 50,
              'returns_total': 0,
              'net_sales': 50,
              'invoice_count': 1,
              'return_rate': 0
            }
          ],
          'summary': {
            ...row,
            'gross_sales': 50,
            'sales_discount': 0,
            'sales_total': 50,
            'returns_total': 0,
            'net_sales': 50,
            'invoice_count': 1,
            'return_rate': 0
          }
        },
    ];
    return response;
  }
}
