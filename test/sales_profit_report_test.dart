import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/accounting_reports/data/financial_accounting_api_service.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_pdf.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/accounting_report_preview.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/sales_profit_report_screen.dart';
import 'package:doctorbike/features/admin/accounting_reports/presentation/views/sales_profit_product_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/accounting_printing_stub.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Almarai')
          ..addFont(
              rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
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
      final detailDropdown = find.byWidgetPredicate((widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'طريقة العرض');
      tester
          .widget<DropdownButtonFormField<String>>(detailDropdown)
          .onChanged!('detail');
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

  for (final width in [320.0, 1280.0]) {
    testWidgets('product profit dashboard, filters and export agree at $width',
        (tester) async {
      installAccountingPrintingStub();
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _ProfitApi();
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('product-profit-evidence'),
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'Almarai'),
          home: SalesProfitReportScreen(
              service: FinancialAccountingApiService(api: api)),
        ),
      ));
      await settleAccountingPreview(tester);
      final viewDropdown = find.byWidgetPredicate((widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'طريقة العرض');
      tester
          .widget<DropdownButtonFormField<String>>(viewDropdown)
          .onChanged!('product');
      await settleAccountingPreview(tester);
      expect(api.last!['group_by'], 'product');
      expect(find.text('المستودع: المخزون العام'), findsOneWidget);
      expect(find.text('إظهار السحوبات غير المفوترة'), findsNothing);
      final document = tester
          .widget<SalesProfitProductDashboard>(
              find.byType(SalesProfitProductDashboard))
          .document;
      expect(document.kind, 'sales_profit_by_product');
      expect(document.rows.first[10], '90.00');
      expect(document.rows.first[11], '50.00');
      expect(document.rows.first[12], '125.00%');
      expect(document.summary['نسبة الربح على التكلفة'], '50.00%');
      expect(document.charts, hasLength(2));
      expect(document.charts.first.entries.single.values.single, 125);
      expect(document.charts.last.entries.last.values.last, -20);
      expect(document.selection, contains('المجموعة: الكل'));
      await _evidence(tester, [document], width);
      await tester.ensureVisible(find.text('تفصيل ربحية الأصناف'));
      await settleAccountingPreview(tester);
      await _dashboardEvidence(tester, width, 'table');
      await tester.ensureVisible(find.text('مقارنة المبيعات والربح'));
      await settleAccountingPreview(tester);
      await _dashboardEvidence(tester, width, 'charts');
      expect(tester.takeException(), isNull);

      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await settleAccountingPreview(tester);
      final categoryDropdown = find.byWidgetPredicate((widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'المجموعة');
      tester
          .widget<DropdownButtonFormField<String>>(categoryDropdown)
          .onChanged!('4');
      await settleAccountingPreview(tester);
      expect(find.byType(AccountingReportPreview), findsNothing);
      expect(find.byType(SalesProfitProductDashboard), findsNothing);
      expect(find.text('مقارنة المبيعات والربح'), findsNothing);
      await tester.ensureVisible(find.text('تطبيق وعرض التقرير'));
      await tester.tap(find.text('تطبيق وعرض التقرير'));
      await settleAccountingPreview(tester);
      expect(api.last!['category_id'], '4');
      final filtered = tester
          .widget<SalesProfitProductDashboard>(
              find.byType(SalesProfitProductDashboard))
          .document;
      expect(filtered.selection, contains('المجموعة: قطع غيار'));
      expect(filtered.summary['إجمالي الربح قبل المصاريف'], '—');
      expect(filtered.charts.last.entries.first.values.last, isNull);
      expect(
          find.textContaining('تكلفة بعض العمليات غير مكتملة'), findsOneWidget);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await settleAccountingPreview(tester);
      tester
          .widget<DropdownButtonFormField<String>>(viewDropdown)
          .onChanged!('invoice');
      await settleAccountingPreview(tester);
      expect(api.last!.containsKey('category_id'), isFalse);
      expect(api.last!.containsKey('group_by'), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _dashboardEvidence(
    WidgetTester tester, double width, String name) async {
  final folder = Platform.environment['ACCOUNTING_REPORT_EVIDENCE_DIR'];
  if (folder == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('product-profit-evidence')));
  final screenshot = await boundary.toImage();
  await tester.runAsync(() async {
    final data = await screenshot.toByteData(format: ui.ImageByteFormat.png);
    await File('$folder/product_${width.toInt()}_$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
  });
  screenshot.dispose();
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
        if (queryParameters['group_by'] == 'product')
          'product_report':
              _productReport(queryParameters['category_id'] != null),
      }
    });
  }
}

Map<String, dynamic> _productReport(bool missingCost) => {
      'summary': {
        'product_count': 2,
        'purchased_quantity': 10,
        'sold_quantity': 3,
        'bonus_quantity': 1,
        'purchase_total': 200,
        'sales_total': 90,
        'cost_total': missingCost ? null : 60,
        'discount': 10,
        'profit': missingCost ? null : 30,
        'profit_percent': missingCost ? null : 50,
        'missing_cost_count': missingCost ? 1 : 0,
      },
      'rows': [
        {
          'product_code': 'P001',
          'product': 'قطعة غيار أصلية للدراجة',
          'is_service': false,
          'purchased_quantity': 10,
          'purchase_total': 200,
          'sold_quantity': 2,
          'bonus_quantity': 0,
          'unit_cost': 20,
          'price': 45,
          'discount': 10,
          'cost_total': missingCost ? null : 40,
          'sales_total': 90,
          'profit': missingCost ? null : 50,
          'profit_percent': missingCost ? null : 125,
        },
        {
          'product_code': 'P002',
          'product': 'بونص',
          'is_service': false,
          'purchased_quantity': 0,
          'purchase_total': 0,
          'sold_quantity': 1,
          'bonus_quantity': 1,
          'unit_cost': 20,
          'price': 0,
          'discount': 0,
          'cost_total': 20,
          'sales_total': 0,
          'profit': -20,
          'profit_percent': -100,
        },
      ],
      'charts': {
        'top_products': [
          if (!missingCost)
            {'product': 'قطعة غيار أصلية للدراجة', 'profit_percent': 125},
        ],
        'comparison': [
          {
            'product': 'قطعة غيار أصلية للدراجة',
            'sales_total': 90,
            'profit': missingCost ? null : 50
          },
          {'product': 'بونص', 'sales_total': 0, 'profit': -20},
        ],
      },
      'options': {
        'categories': [
          {'id': 4, 'name': 'قطع غيار'}
        ],
        'store_sections': [
          {'id': 8, 'name': 'الرف الأول'}
        ],
      },
      'notes': [
        'نسبة الربح على التكلفة = الربح ÷ تكلفة المباع × 100.',
        'المشتريات حسب تاريخ الاستلام، ولا تطرح من الربح مرة أخرى.',
      ],
    };
