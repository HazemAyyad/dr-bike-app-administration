import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/assets_models/assets_log_model.dart';

class FinancialReportPdfBuilder {
  FinancialReportPdfBuilder._();

  static final PdfColor _brand = PdfColor.fromHex('#6B65BD');
  static final PdfColor _border = PdfColor.fromHex('#D1D5DB');
  static final PdfColor _muted = PdfColor.fromHex('#6B7280');
  static final PdfColor _soft = PdfColor.fromHex('#F5F3FF');

  static Future<pw.Font> _font(String weight) async => pw.Font.ttf(
        await rootBundle.load('assets/fonts/Almarai/Almarai-$weight.ttf'),
      );

  static Future<pw.MemoryImage?> _logo() async {
    try {
      final data =
          await rootBundle.load('assets/images/purchase_invoice_logo.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _money(dynamic value) =>
      NumberFormat('#,##0.00').format(double.tryParse('$value') ?? 0);

  static Future<Uint8List> buildExpenses({
    required Map<String, dynamic> payload,
    required String title,
    String? from,
    String? to,
  }) async {
    final rows = (payload['rows'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final summary = Map<String, dynamic>.from(
      payload['summary'] as Map? ?? const {},
    );
    return _build(
      title: title,
      subtitle: _periodText(from, to),
      summary: [
        ['عدد الحركات', '${summary['count'] ?? rows.length}'],
        ['إجمالي المصاريف', _money(summary['total'])],
        ['متوسط المصروف', _money(summary['average'])],
      ],
      headers: const [
        'الملاحظات',
        'الصندوق',
        'المبلغ',
        'البيان',
        'التاريخ',
        '#'
      ],
      data: rows.asMap().entries.map((entry) {
        final row = entry.value;
        return [
          '${row['notes'] ?? '-'}',
          '${row['box_name'] ?? '-'}',
          '${_money(row['price'])} ${row['currency'] ?? ''}',
          '${row['name'] ?? '-'}',
          '${row['date'] ?? '-'}',
          '${entry.key + 1}',
        ];
      }).toList(),
      widths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(2.1),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(.45),
      },
      rtlColumns: const {0, 1, 2, 3},
    );
  }

  static Future<Uint8List> buildAssetLogs({
    required List<AssetLogModel> logs,
    required String title,
    String? period,
  }) async {
    final total =
        logs.fold<double>(0, (sum, log) => sum + log.depreciationAmount);
    return _build(
      title: title,
      subtitle: period == null || period.isEmpty
          ? 'جميع فترات الإهلاك'
          : 'فترة الإهلاك: $period',
      summary: [
        ['عدد الحركات', '${logs.length}'],
        ['عدد الأصول', '${logs.map((e) => e.assetId).toSet().length}'],
        ['إجمالي الإهلاك', _money(total)],
      ],
      headers: const [
        'القيمة بعد',
        'قيمة الإهلاك',
        'القيمة قبل',
        'النسبة',
        'الأصل',
        'الفترة',
        '#'
      ],
      data: logs.asMap().entries.map((entry) {
        final log = entry.value;
        return [
          _money(log.total),
          _money(log.depreciationAmount),
          _money(log.valueBefore),
          '${log.depreciationRate}%',
          log.assetName,
          log.depreciationPeriod.isEmpty
              ? DateFormat('yyyy-MM').format(log.depreciationDate)
              : log.depreciationPeriod,
          '${entry.key + 1}',
        ];
      }).toList(),
      widths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(.8),
        4: pw.FlexColumnWidth(2.1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(.4),
      },
      rtlColumns: const {4},
    );
  }

  static Future<Uint8List> buildPayroll({
    required Map<String, dynamic> payload,
  }) async {
    final rows = (payload['rows'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final summary = Map<String, dynamic>.from(
      payload['summary'] as Map? ?? const {},
    );
    final month = '${payload['month'] ?? ''}';

    return _build(
      title: 'تقرير الرواتب الشهري',
      subtitle: month.isEmpty ? 'جميع الفترات' : 'شهر الرواتب: $month',
      summary: [
        ['عدد الموظفين', '${summary['employees_count'] ?? rows.length}'],
        ['إجمالي الاستحقاقات', _money(summary['gross_total'])],
        ['السلف المسواة', _money(summary['advances_total'])],
        ['المدفوع النقدي', _money(summary['paid_total'])],
        ['المتبقي', _money(summary['remaining_total'])],
        [
          'إقرارات الاستلام',
          '${summary['received_count'] ?? 0} مستلم • '
              '${summary['pending_count'] ?? 0} معلق • '
              '${summary['disputed_count'] ?? 0} اعتراض'
        ],
      ],
      headers: const [
        'الإقرارات',
        'الحالة',
        'المتبقي',
        'المدفوع',
        'السلف',
        'الاستحقاق',
        'الموظف',
        '#',
      ],
      data: rows.asMap().entries.map((entry) {
        final row = entry.value;
        return [
          '${row['received_count'] ?? 0} مستلم / '
              '${row['pending_count'] ?? 0} معلق / '
              '${row['disputed_count'] ?? 0} اعتراض',
          _payrollStatus('${row['status'] ?? ''}'),
          '${_money(row['remaining'])} شيكل',
          '${_money(row['total_paid'])} شيكل',
          '${_money(row['advances_applied'])} شيكل',
          '${_money(row['gross_entitlement'])} شيكل',
          '${row['employee_name'] ?? '-'}',
          '${entry.key + 1}',
        ];
      }).toList(),
      widths: const {
        0: pw.FlexColumnWidth(1.45),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1.15),
        6: pw.FlexColumnWidth(1.8),
        7: pw.FlexColumnWidth(.4),
      },
      rtlColumns: const {0, 1, 2, 3, 4, 5, 6},
    );
  }

  static String _payrollStatus(String status) {
    if (status == 'paid') return 'مدفوع بالكامل';
    if (status == 'partially_paid') return 'مدفوع جزئياً';
    if (status == 'cancelled') return 'ملغي';
    return 'محسوب';
  }

  static Future<Uint8List> _build({
    required String title,
    required String subtitle,
    required List<List<String>> summary,
    required List<String> headers,
    required List<List<String>> data,
    required Map<int, pw.TableColumnWidth> widths,
    required Set<int> rtlColumns,
  }) async {
    final regular = await _font('Regular');
    final bold = await _font('Bold');
    final logo = await _logo();
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(25, 24, 25, 24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('دكتور بايك - تقرير محاسبي',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 8, color: _muted)),
              pw.Text('${context.pageNumber} / ${context.pagesCount}',
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ),
        build: (_) => [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Row(children: [
              if (logo != null) pw.Image(logo, height: 70, width: 110),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('دكتور بايك',
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                          font: bold, fontSize: 22, color: _brand)),
                  pw.Text('نظام الإدارة المالية',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(fontSize: 10, color: _muted)),
                ],
              ),
            ]),
          ),
          pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 10),
              height: 1.5,
              color: _brand),
          pw.Text(
            title,
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: bold, fontSize: 17),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$subtitle • تاريخ الإنشاء: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: summary
                .map((item) => pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                        padding: const pw.EdgeInsets.all(9),
                        decoration: pw.BoxDecoration(
                          color: _soft,
                          border: pw.Border.all(color: _border),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(children: [
                          pw.Text(item[0],
                              textDirection: pw.TextDirection.rtl,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 8, color: _muted)),
                          pw.SizedBox(height: 3),
                          pw.Text(item[1],
                              style: pw.TextStyle(font: bold, fontSize: 11)),
                        ]),
                      ),
                    ))
                .toList(),
          ),
          pw.SizedBox(height: 12),
          if (data.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(24),
              decoration:
                  pw.BoxDecoration(border: pw.Border.all(color: _border)),
              child: pw.Center(
                child: pw.Text(
                  'لا توجد بيانات لهذه الفترة',
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              tableDirection: pw.TextDirection.ltr,
              headerDirection: pw.TextDirection.rtl,
              columnWidths: widths,
              headerDecoration: pw.BoxDecoration(color: _brand),
              headerStyle:
                  pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignments: {
                for (var index = 0; index < headers.length; index++)
                  index: rtlColumns.contains(index)
                      ? pw.Alignment.centerRight
                      : pw.Alignment.center,
              },
              headerAlignments: {
                for (var index = 0; index < headers.length; index++)
                  index: rtlColumns.contains(index)
                      ? pw.Alignment.centerRight
                      : pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: _border, width: .6),
              oddRowDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#F9FAFB')),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              cellBuilder: (index, value, rowNumber) => pw.Text(
                value.toString(),
                textDirection: rtlColumns.contains(index)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                textAlign: rtlColumns.contains(index)
                    ? pw.TextAlign.right
                    : pw.TextAlign.center,
                style: pw.TextStyle(
                  font: rtlColumns.contains(index) ? regular : bold,
                  fontSize: 7.5,
                ),
              ),
            ),
        ],
      ),
    );
    return document.save();
  }

  static String _periodText(String? from, String? to) {
    if ((from == null || from.isEmpty) && (to == null || to.isEmpty)) {
      return 'جميع التواريخ';
    }
    return 'من ${from == null || from.isEmpty ? 'البداية' : from} إلى ${to == null || to.isEmpty ? 'اليوم' : to}';
  }
}
