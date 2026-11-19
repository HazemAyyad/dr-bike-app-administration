import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import 'accounting_report_chart.dart';
import 'accounting_report_pdf.dart';

AccountingReportDocument buildSalesProfitProductDocument(
    Map<String, dynamic> report, String sourceLabel) {
  final data = report['product_report'] as Map;
  final summary = data['summary'] as Map;
  final filters = report['filters'] as Map;
  final money = NumberFormat('#,##0.00', 'en');
  final quantity = NumberFormat('#,##0.###', 'en');
  final precise = NumberFormat('#,##0.######', 'en');
  String amount(dynamic value) => value is num ? money.format(value) : '—';
  String qty(dynamic value) => value is num ? quantity.format(value) : '—';
  String cost(dynamic value) => value is num ? precise.format(value) : '—';
  String percent(dynamic value) => value is num ? '${amount(value)}%' : '—';
  final options = data['options'] as Map;
  String selected(String key, String collection) {
    final id = filters[key];
    if (id == null) return 'الكل';
    for (final option in options[collection] as List) {
      if ('${option['id']}' == '$id') return '${option['name']}';
    }
    return '#$id';
  }

  final rows = <List<String>>[
    for (final row in (data['rows'] as List).cast<Map>())
      [
        '${row['product_code']}',
        '${row['product']}',
        row['is_service'] == true ? '—' : qty(row['purchased_quantity']),
        row['is_service'] == true ? '—' : amount(row['purchase_total']),
        row['is_service'] == true ? '—' : qty(row['sold_quantity']),
        row['is_service'] == true ? '—' : qty(row['bonus_quantity']),
        cost(row['unit_cost']),
        cost(row['price']),
        amount(row['discount']),
        amount(row['cost_total']),
        amount(row['sales_total']),
        amount(row['profit']),
        percent(row['profit_percent']),
      ],
    [
      '',
      'الإجمالي',
      qty(summary['purchased_quantity']),
      amount(summary['purchase_total']),
      qty(summary['sold_quantity']),
      qty(summary['bonus_quantity']),
      '',
      '',
      amount(summary['discount']),
      amount(summary['cost_total']),
      amount(summary['sales_total']),
      amount(summary['profit']),
      percent(summary['profit_percent']),
    ],
  ];
  final charts = data['charts'] as Map;
  return AccountingReportDocument(
    kind: 'sales_profit_by_product',
    title: 'ربحية المبيعات حسب الصنف',
    from: '${filters['from_date']}',
    to: '${filters['to_date']}',
    currency: '${filters['currency']}',
    columns: const [
      'رقم الصنف',
      'الصنف',
      'الكمية المشتراة',
      'قيمة المشتريات',
      'صافي الكمية المباعة',
      'منها بونص',
      'متوسط تكلفة القطعة',
      'متوسط سعر البيع',
      'الخصم',
      'تكلفة المباع',
      'صافي المبيعات',
      'إجمالي الربح',
      'نسبة الربح على التكلفة',
    ],
    rows: rows,
    subtotalRows: {rows.length - 1},
    columnWeights: const [
      .8,
      2.2,
      1.15,
      1.3,
      1.3,
      .9,
      1.25,
      1.2,
      .9,
      1.3,
      1.3,
      1.3,
      1.7
    ],
    summary: {
      'عدد الأصناف': '${summary['product_count']}',
      'صافي المبيعات': amount(summary['sales_total']),
      'تكلفة المباع': amount(summary['cost_total']),
      'إجمالي الربح قبل المصاريف': amount(summary['profit']),
      'نسبة الربح على التكلفة': percent(summary['profit_percent']),
      'قيمة المشتريات المستلمة': amount(summary['purchase_total']),
    },
    notes: (data['notes'] as List).cast<String>(),
    selection:
        '$sourceLabel • ${filters['include_returns'] == true ? 'مع المرتجعات' : 'بدون المرتجعات'}'
        ' • المجموعة: ${selected('category_id', 'categories')}'
        ' • قسم المخزن: ${selected('store_section_id', 'store_sections')}'
        ' • المستودع: المخزون العام',
    charts: [
      AccountingReportChart(
        title: 'أعلى الأصناف ربحية حسب نسبة الربح على التكلفة',
        series: const ['نسبة الربح على التكلفة'],
        entries: [
          for (final row in charts['top_products'] as List)
            AccountingReportChartEntry('${row['product']}',
                [(row['profit_percent'] as num?)?.toDouble()]),
        ],
        unit: '%',
      ),
      AccountingReportChart(
        title: 'مقارنة المبيعات والربح',
        series: const ['صافي المبيعات', 'إجمالي الربح'],
        entries: [
          for (final row in charts['comparison'] as List)
            AccountingReportChartEntry('${row['product']}', [
              (row['sales_total'] as num?)?.toDouble(),
              (row['profit'] as num?)?.toDouble(),
            ]),
        ],
        unit: '${filters['currency']}',
      ),
    ],
  );
}

class SalesProfitProductDashboard extends StatelessWidget {
  const SalesProfitProductDashboard({Key? key, required this.document})
      : super(key: key);
  final AccountingReportDocument document;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(document.title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${document.from} — ${document.to} • ${document.currency}'),
          Text(document.selection),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (_, constraints) {
            final count = constraints.maxWidth >= 900
                ? 3
                : (constraints.maxWidth >= 550 ? 2 : 1);
            final width = (constraints.maxWidth - (count - 1) * 12) / count;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final entry in document.summary.entries)
                SizedBox(
                  width: width,
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: const Color(0xFFF0F4FB),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key),
                          const SizedBox(height: 8),
                          Text(entry.value,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
            ]);
          }),
          const SizedBox(height: 16),
          if (document.rows.length == 1)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد مبيعات أو مشتريات مطابقة للفلاتر.'))
          else
            PaginatedDataTable(
              key: ObjectKey(document),
              header: const Text('تفصيل ربحية الأصناف'),
              columns: [
                for (final title in document.columns)
                  DataColumn(label: Text(title)),
              ],
              source: _ProductTableSource(document),
              rowsPerPage:
                  document.rows.length < 10 ? document.rows.length : 10,
              availableRowsPerPage: const [5, 10, 20],
              onRowsPerPageChanged: null,
              showFirstLastButtons: true,
              columnSpacing: 22,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 70,
            ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (_, constraints) {
            final wide = constraints.maxWidth >= 850;
            final width =
                wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              for (final chart in document.charts)
                SizedBox(
                    width: width,
                    child: AccountingReportChartView(chart: chart)),
            ]);
          }),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('ملخص التقرير وطريقة الحساب',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 8),
                  for (final note in document.notes)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(note)),
                ],
              ),
            ),
          ),
        ],
      );
}

class _ProductTableSource extends DataTableSource {
  _ProductTableSource(this.document);
  final AccountingReportDocument document;
  @override
  DataRow getRow(int index) => DataRow.byIndex(
        index: index,
        color: document.subtotalRows.contains(index)
            ? const WidgetStatePropertyAll(Color(0xFFE8EDF7))
            : null,
        cells: [
          for (final value in document.rows[index]) DataCell(Text(value)),
        ],
      );
  @override
  int get rowCount => document.rows.length;
  @override
  bool get isRowCountApproximate => false;
  @override
  int get selectedRowCount => 0;
}
