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

  for (final size in [const Size(320, 740), const Size(1280, 900)]) {
    testWidgets('accounting report is readable at ${size.width}',
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
          'group_by': 'customer',
          'include_returns': 1,
          'sort': 'sales_desc',
        },
      ));
      final boundary = GlobalKey();
      await tester.pumpWidget(GetMaterialApp(
        locale: const Locale('ar'),
        theme: ThemeData(fontFamily: 'AccountingAlmarai'),
        home: RepaintBoundary(
            key: boundary, child: const SalesAccountingScreen()),
      ));
      await settleAccountingPreview(tester);
      expect(find.text('تقارير محاسبية'), findsOneWidget);
      expect(find.text('تذكّر خياراتي'), findsOneWidget);
      expect(c.rows, hasLength(2));
      expect(find.byType(AccountingReportPreview), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
      await revealAccountingDetail(tester, find.text('تفاصيل الحركات'));
      await tester.tap(find.text('تفاصيل الحركات'));
      await tester.pumpAndSettle();
      expect(find.text('الإجمالي'), findsOneWidget);
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
          await File('${dir.path}/accounting-${size.width.toInt()}.png')
              .writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
          if (size.width > 1000) {
            final pdf = await SalesAccountingExport.buildPdf(c);
            expect(pdf.sublist(0, 4), [37, 80, 68, 70]);
            await File('${dir.path}/accounting-report.pdf').writeAsBytes(pdf);
            await File('${dir.path}/accounting-report.csv')
                .writeAsString(SalesAccountingExport.buildCsv(c));
          }
        });
      }
    });
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
      'key': 'customer:1',
      'label': 'زبون تجريبي',
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
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: {
        'status': 'success',
        'data': {
          'filters': {
            ...request!,
            'include_returns': request!['include_returns'] == 1
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
              'key': 'customer:2',
              'label': 'مرتجع من فترة سابقة',
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
          'currency': 'شيكل',
          'people': [
            {'key': 'customer:1', 'name': 'زبون تجريبي', 'type': 'customer'}
          ],
          'notes': ['نسبة المرتجعات من مبيعات الصف نفسه.'],
        }
      },
    );
  }
}
