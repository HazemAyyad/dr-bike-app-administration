import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BoxReportPdfBuilder {
  BoxReportPdfBuilder._();

  static final _brand = PdfColor.fromHex('#6B65BD');
  static final _border = PdfColor.fromHex('#D1D5DB');
  static final _muted = PdfColor.fromHex('#6B7280');
  static final _row = PdfColor.fromHex('#F9FAFB');

  static Future<Uint8List> build(Map<String, dynamic> report) async {
    final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf'));
    final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf'));
    final logo = pw.MemoryImage(
        (await rootBundle.load('assets/images/purchase_invoice_logo.jpg'))
            .buffer
            .asUint8List());
    final box = _map(report['box']);
    final summary = _map(report['summary']);
    final filters = _map(report['filters']);
    final logs = _list(report['logs']);
    final currency = _text(box['currency'], '—');
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(26, 24, 26, 26),
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      header: (_) => pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(children: [
          pw.Image(logo, width: 125, height: 76),
          pw.Spacer(),
          pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(fontSize: 8, color: _muted)),
          pw.Spacer(),
          pw.Text('دكتور بايك - تقرير صندوق',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: bold, fontSize: 20, color: _brand)),
        ]),
      ),
      footer: (context) => pw.Row(children: [
        pw.Text('${context.pageNumber} / ${context.pagesCount}',
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(fontSize: 8, color: _muted)),
        pw.Spacer(),
        pw.Text('تم إنشاء التقرير من تطبيق Doctor Bike',
            style: pw.TextStyle(fontSize: 8, color: _muted)),
      ]),
      build: (_) => [
        pw.Container(height: 1.4, color: _brand),
        pw.SizedBox(height: 8),
        pw.Center(
            child: pw.Text('تقرير حركات الصندوق',
                style: pw.TextStyle(font: bold, fontSize: 17))),
        pw.SizedBox(height: 8),
        _meta(box, filters, bold),
        pw.SizedBox(height: 10),
        _summary(summary, currency, bold),
        pw.SizedBox(height: 12),
        logs.isEmpty ? _empty() : _table(logs, bold),
      ],
    ));
    return doc.save();
  }

  static pw.Widget _meta(Map<String, dynamic> box, Map<String, dynamic> filters,
          pw.Font bold) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border),
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Row(children: [
          _metaItem('اسم الصندوق', _text(box['name'], '—'), bold),
          _metaItem('العملة', _text(box['currency'], '—'), bold),
          _metaItem('من تاريخ', _text(filters['from_date'], '—'), bold),
          _metaItem('إلى تاريخ', _text(filters['to_date'], '—'), bold),
        ]),
      );

  static pw.Widget _metaItem(String label, String value, pw.Font bold) =>
      pw.Expanded(
          child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 9)),
          pw.SizedBox(height: 3),
          pw.Text(value, textDirection: pw.TextDirection.rtl)
        ],
      ));

  static pw.Widget _summary(
      Map<String, dynamic> summary, String currency, pw.Font bold) {
    final items = [
      ['الرصيد الافتتاحي', summary['opening_balance']],
      ['إجمالي الوارد', summary['incoming']],
      ['إجمالي الصادر', summary['outgoing']],
      ['صافي الحركة', summary['net']],
      ['الرصيد الختامي', summary['closing_balance']],
    ];
    return pw.Row(
        children: items
            .map((item) => pw.Expanded(
                    child: pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                  padding: const pw.EdgeInsets.all(7),
                  decoration: pw.BoxDecoration(
                      color: _row, border: pw.Border.all(color: _border)),
                  child: pw.Column(children: [
                    pw.Text('${item[0]}',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 3),
                    pw.Text('${_money(item[1])} $currency',
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(font: bold, fontSize: 11))
                  ]),
                )))
            .toList());
  }

  static pw.Widget _empty() => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(24),
      alignment: pw.Alignment.center,
      decoration:
          pw.BoxDecoration(color: _row, border: pw.Border.all(color: _border)),
      child: pw.Text('لا توجد حركات مطابقة للفلاتر المحددة'));

  static pw.Widget _table(List<Map<String, dynamic>> logs, pw.Font bold) {
    final rows = logs.asMap().entries.map((entry) {
      final log = entry.value;
      final signed = _number(log['signed_amount']);
      return [
        signed < 0 ? _money(signed.abs()) : '—',
        signed > 0 ? _money(signed) : '—',
        _text(log['note'], '—'),
        _text(log['description'], '—'),
        _type(log['type']),
        _date(log['created_at']),
        '${entry.key + 1}'
      ];
    }).toList();
    return pw.TableHelper.fromTextArray(
      tableDirection: pw.TextDirection.ltr,
      headerDirection: pw.TextDirection.rtl,
      headers: const [
        'صادر',
        'وارد',
        'ملاحظة',
        'البيان',
        'النوع',
        'التاريخ',
        '#'
      ],
      data: rows,
      headerStyle:
          pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: _brand),
      oddRowDecoration: pw.BoxDecoration(color: _row),
      border: pw.TableBorder.all(color: _border, width: .7),
      cellPadding: const pw.EdgeInsets.all(5),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center
      },
    );
  }

  static String _type(dynamic value) {
    switch ('$value') {
      case 'add':
        return 'إضافة';
      case 'minus':
        return 'سحب';
      case 'transfer':
        return 'تحويل';
      case 'maintenance':
        return 'صيانة';
      case 'expense':
        return 'مصروف';
      case 'payroll':
        return 'رواتب';
      default:
        return 'حركة';
    }
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
  static String _text(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  static String _money(dynamic value) =>
      NumberFormat('#,##0.00').format(_number(value));
  static String _date(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    return date == null ? '—' : DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}
