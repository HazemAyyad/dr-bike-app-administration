import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DebtLedgerPdf {
  static const _purple = PdfColor.fromInt(0xFF6B65BD);
  static const _ink = PdfColor.fromInt(0xFF263238);
  static const _soft = PdfColor.fromInt(0xFFF4F3FC);

  static Future<Uint8List> build(Map<String, dynamic> report) async {
    final regular = pw.Font.ttf(await rootBundle.load(
      'assets/fonts/Almarai/Almarai-Regular.ttf',
    ));
    final bold = pw.Font.ttf(await rootBundle.load(
      'assets/fonts/Almarai/Almarai-Bold.ttf',
    ));
    pw.MemoryImage? logo;
    try {
      logo = pw.MemoryImage((await rootBundle.load(
        'assets/images/purchase_invoice_logo.jpg',
      ))
          .buffer
          .asUint8List());
    } catch (_) {}

    final details =
        Map<String, dynamic>.from(report['source_details'] as Map? ?? {});
    final images = <String, pw.ImageProvider?>{};
    for (final detail in details.values.whereType<Map>()) {
      for (final item
          in (detail['items'] as List? ?? const []).whereType<Map>()) {
        final url = item['image_path']?.toString();
        if (url != null && url.startsWith('http') && !images.containsKey(url)) {
          try {
            images[url] = await networkImage(url);
          } catch (_) {
            images[url] = null;
          }
        }
      }
    }

    final transactions =
        (report['transactions'] as List? ?? const []).whereType<Map>().toList();
    final person = Map<String, dynamic>.from(report['person'] as Map? ?? {});
    final currency = _currency(report['period_label']?.toString() ?? '');
    final document =
        pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => _header(logo, bold),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Text('${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (_) => [
        pw.Center(
            child: pw.Text('كشف حساب',
                style: pw.TextStyle(font: bold, fontSize: 19, color: _purple))),
        pw.SizedBox(height: 14),
        _meta('صاحب الحساب', person['name']?.toString() ?? '—', bold),
        _meta('رقم الهاتف', person['phone']?.toString() ?? '—', bold),
        _meta('الفترة', report['period_label']?.toString() ?? '—', bold),
        _meta('تاريخ الإصدار', report['generated_at']?.toString() ?? '—', bold),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              color: _soft, borderRadius: pw.BorderRadius.circular(7)),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _stat('مبالغ مستحقة لنا', report['total_taken'], currency,
                    PdfColors.green700, bold),
                _stat('مبالغ مستحقة علينا', report['total_given'], currency,
                    PdfColors.red700, bold),
                _stat(
                    'صافي الرصيد', report['balance'], currency, _purple, bold),
              ]),
        ),
        pw.SizedBox(height: 16),
        ...transactions.asMap().entries.expand((entry) {
          final tx = entry.value;
          final id = tx['id']?.toString() ?? '';
          final taken = tx['type'] == 'taken';
          final widgets = <pw.Widget>[
            _transaction(entry.key + 1, tx, taken, currency, bold)
          ];
          final detail = details[id];
          if (detail is Map) {
            widgets.add(_sourceDetail(detail, currency, images, bold));
          }
          widgets.add(pw.SizedBox(height: 7));
          return widgets;
        }),
      ],
    ));
    return document.save();
  }

  static pw.Widget _header(pw.MemoryImage? logo, pw.Font bold) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _purple, width: 2))),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DOCTOR BIKE',
                        style: pw.TextStyle(
                            font: bold, fontSize: 20, color: _purple)),
                    pw.Text('تقرير دفتر الديون',
                        style: pw.TextStyle(
                            font: bold, fontSize: 12, color: _ink)),
                  ]),
              if (logo != null) pw.Image(logo, height: 58),
            ]),
      );

  static pw.Widget _meta(String label, String value, pw.Font bold) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.RichText(
            text: pw.TextSpan(children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: bold)),
          pw.TextSpan(text: value)
        ])),
      );

  static pw.Widget _stat(String label, dynamic value, String currency,
          PdfColor color, pw.Font bold) =>
      pw.Column(children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text('${_money(value)} $currency',
            style: pw.TextStyle(font: bold, fontSize: 12, color: color)),
      ]);

  static pw.Widget _transaction(
          int index, Map tx, bool taken, String currency, pw.Font bold) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('$index. ${tx['transaction_date'] ?? '—'}',
                        style: pw.TextStyle(font: bold, color: _ink)),
                    pw.Text(
                        '${taken ? 'مستحق لنا' : 'مستحق علينا'}  ${_money(tx['amount'])} $currency',
                        style: pw.TextStyle(
                            font: bold,
                            color:
                                taken ? PdfColors.green700 : PdfColors.red700)),
                  ]),
              if ((tx['note']?.toString().trim() ?? '').isNotEmpty)
                pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 5),
                    child: pw.Text(tx['note'].toString(),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700))),
              pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                      'الرصيد بعد الحركة: ${_money(tx['balance_after'])} $currency',
                      style: const pw.TextStyle(fontSize: 9))),
            ]),
      );

  static pw.Widget _sourceDetail(Map detail, String currency,
      Map<String, pw.ImageProvider?> images, pw.Font bold) {
    final items =
        (detail['items'] as List? ?? const []).whereType<Map>().toList();
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 5),
      padding: const pw.EdgeInsets.all(8),
      color: PdfColors.grey100,
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(detail['title']?.toString() ?? '',
            style: pw.TextStyle(font: bold, color: _purple)),
        ...items.map((item) {
          final url = item['image_path']?.toString();
          final image = url == null ? null : images[url];
          return pw.Container(
              margin: const pw.EdgeInsets.only(top: 6),
              child: pw.Row(children: [
                pw.Container(
                    width: 42,
                    height: 42,
                    color: PdfColors.white,
                    child: image == null
                        ? pw.Center(child: pw.Text('—'))
                        : pw.Image(image, fit: pw.BoxFit.cover)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                    child: pw.Text(item['name']?.toString() ?? 'منتج',
                        style: pw.TextStyle(font: bold, fontSize: 9))),
                pw.Text(
                    '${_money(item['quantity'])} × ${_money(item['unit_price'])} = ${_money(item['line_total'])} $currency',
                    style: const pw.TextStyle(fontSize: 8)),
              ]));
        }),
      ]),
    );
  }

  static String _currency(String label) => label.contains('دولار')
      ? 'دولار'
      : label.contains('دينار')
          ? 'دينار'
          : 'شيكل';
  static String _money(dynamic value) =>
      (double.tryParse(value?.toString() ?? '0') ?? 0).toStringAsFixed(2);
}
