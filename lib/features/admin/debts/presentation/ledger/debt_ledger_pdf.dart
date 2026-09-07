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

    final rawDetails = report['source_details'];
    final details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};
    final isSummary = report['detail_level']?.toString() == 'summary';
    final includeImages =
        report['detail_level']?.toString() == 'detailed_with_images';
    final images = <String, pw.ImageProvider?>{};
    for (final detail in !includeImages
        ? const Iterable<Map<dynamic, dynamic>>.empty()
        : details.values.whereType<Map>()) {
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
    final takenLabel =
        report['taken_label']?.toString().trim().isNotEmpty == true
            ? report['taken_label'].toString().trim()
            : 'أخذت';
    final givenLabel =
        report['given_label']?.toString().trim().isNotEmpty == true
            ? report['given_label'].toString().trim()
            : 'أعطيت';
    final document =
        pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.fromLTRB(40, 28, 40, 28),
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
                _stat('إجمالي $takenLabel', report['total_taken'], currency,
                    PdfColors.green700, bold),
                _stat('إجمالي $givenLabel', report['total_given'], currency,
                    PdfColors.red700, bold),
                _stat(
                    'صافي الرصيد', report['balance'], currency, _purple, bold),
              ]),
        ),
        pw.SizedBox(height: 16),
        if (isSummary)
          ..._summaryTransactions(
                  transactions, currency, bold, takenLabel, givenLabel)
              .map((row) => pw.Center(
                    child: pw.SizedBox(width: 410, child: row),
                  ))
        else ...[
          _detailTableHeader(bold, takenLabel, givenLabel),
          ...transactions.asMap().entries.expand((entry) {
            final tx = entry.value;
            final id = tx['id']?.toString() ?? '';
            final taken = tx['type'] == 'taken';
            final widgets = <pw.Widget>[
              _transaction(entry.key + 1, tx, taken, currency, bold, takenLabel,
                  givenLabel)
            ];
            final detail = details[id];
            if (detail is Map) {
              widgets.add(_sourceDetail(
                detail,
                currency,
                images,
                bold,
                includeImages,
              ));
            }
            widgets.add(pw.SizedBox(height: 2));
            return widgets;
          }),
        ],
      ],
    ));
    return document.save();
  }

  static pw.Widget _header(pw.MemoryImage? logo, pw.Font bold) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: _purple, width: 1.3))),
        child: pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Row(children: [
            pw.SizedBox(
              width: 130,
              height: 78,
              child: logo == null
                  ? pw.SizedBox()
                  : pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(logo, height: 78),
                    ),
            ),
            pw.Spacer(),
            pw.Expanded(
              flex: 2,
              child: pw.Text('دكتور بايك - تقرير دفتر الديون',
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                  style:
                      pw.TextStyle(font: bold, fontSize: 20, color: _purple)),
            ),
          ]),
        ),
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

  static pw.Widget _transaction(int index, Map tx, bool taken, String currency,
          pw.Font bold, String takenLabel, String givenLabel) =>
      _detailTableRow([
        '$index',
        tx['transaction_date']?.toString() ?? '—',
        (tx['note']?.toString().trim() ?? '').isEmpty
            ? '—'
            : _displayText(tx['note']),
        taken ? _money(tx['amount']) : '—',
        taken ? '—' : _money(tx['amount']),
        '${_money(tx['balance_after'])} $currency',
      ], bold);

  static pw.Widget _detailTableHeader(
          pw.Font bold, String takenLabel, String givenLabel) =>
      _detailTableRow(
        ['#', 'التاريخ', 'البيان', takenLabel, givenLabel, 'الرصيد'],
        bold,
        header: true,
      );

  static pw.Widget _detailTableRow(List<String> values, pw.Font bold,
      {bool header = false}) {
    const widths = [1, 3, 10, 2, 2, 3];
    return pw.Container(
      decoration: pw.BoxDecoration(
          color: header ? _purple : PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey400, width: .55)),
      child: pw.Row(
        children: List.generate(
            values.length,
            (index) => pw.Expanded(
                  flex: widths[index],
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4, vertical: 5),
                    child: pw.Text(values[index],
                        maxLines: 2,
                        textAlign: index == 2
                            ? pw.TextAlign.right
                            : pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: header || index == 5 ? bold : null,
                          fontSize: 8,
                          color: header ? PdfColors.white : _ink,
                        )),
                  ),
                )),
      ),
    );
  }

  static List<pw.Widget> _summaryTransactions(
    List<Map> transactions,
    String currency,
    pw.Font bold,
    String takenLabel,
    String givenLabel,
  ) {
    final headers = ['التاريخ', 'البيان', takenLabel, givenLabel, 'الرصيد'];
    return [
      _summaryRow(headers, _purple, bold, PdfColors.white),
      ...transactions.asMap().entries.map((entry) {
        final tx = entry.value;
        final taken = tx['type'] == 'taken';
        final note = tx['note']?.toString().trim() ?? '';
        return _summaryRow(
          [
            tx['transaction_date']?.toString() ?? '—',
            note.isEmpty ? '—' : _displayText(note),
            taken ? _money(tx['amount']) : '—',
            taken ? '—' : _money(tx['amount']),
            '${_money(tx['balance_after'])} $currency',
          ],
          entry.key.isEven ? PdfColors.white : _soft,
          bold,
          _ink,
        );
      }),
    ];
  }

  static pw.Widget _summaryRow(List<String> values, PdfColor background,
          pw.Font bold, PdfColor color) =>
      pw.Container(
        color: background,
        child: pw.Row(children: [
          pw.Expanded(
              flex: 5,
              child: _summaryCell(values[0], bold: bold, color: color)),
          pw.Expanded(flex: 10, child: _summaryCell(values[1], color: color)),
          pw.Expanded(flex: 5, child: _summaryCell(values[2], color: color)),
          pw.Expanded(flex: 5, child: _summaryCell(values[3], color: color)),
          pw.Expanded(
              flex: 6,
              child: _summaryCell(values[4], bold: bold, color: color)),
        ]),
      );

  static pw.Widget _summaryCell(
    String value, {
    pw.Font? bold,
    PdfColor color = _ink,
    pw.Alignment alignment = pw.Alignment.centerRight,
  }) =>
      pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Text(
          value,
          maxLines: 2,
          style: pw.TextStyle(font: bold, fontSize: 8, color: color),
        ),
      );

  static pw.Widget _sourceDetail(Map detail, String currency,
      Map<String, pw.ImageProvider?> images, pw.Font bold, bool includeImages) {
    final items =
        (detail['items'] as List? ?? const []).whereType<Map>().toList();
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 1),
      padding: pw.EdgeInsets.zero,
      color: PdfColors.grey100,
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        ...items.map((item) {
          final url = item['image_path']?.toString();
          final image = url == null ? null : images[url];
          return _productRow(
              includeImages,
              image,
              [
                item['name']?.toString() ?? 'منتج',
                '${_money(item['quantity'])} × ${_money(item['unit_price'])} = ${_money(item['line_total'])} $currency',
              ],
              bold);
        }),
      ]),
    );
  }

  static pw.Widget _productRow(bool includeImages, pw.ImageProvider? image,
          List<String> values, pw.Font bold) =>
      pw.Container(
        decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.grey400, width: .45)),
        child: pw.Row(children: [
          if (includeImages)
            pw.SizedBox(
              width: 34,
              height: 27,
              child: image == null
                  ? pw.Center(child: pw.Text('—'))
                  : pw.Image(image, fit: pw.BoxFit.cover),
            ),
          pw.Expanded(flex: 7, child: _productCell(values[0], bold, true)),
          pw.Expanded(flex: 5, child: _productCell(values[1], bold, false)),
        ]),
      );

  static pw.Widget _productCell(String value, pw.Font bold, bool header) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
        child: pw.Text(value,
            maxLines: 2,
            style: pw.TextStyle(font: header ? bold : null, fontSize: 7)),
      );

  static String _currency(String label) => label.contains('دولار')
      ? 'دولار'
      : label.contains('دينار')
          ? 'دينار'
          : 'شيكل';
  static String _money(dynamic value) =>
      (double.tryParse(value?.toString() ?? '0') ?? 0).toStringAsFixed(2);

  static String _displayText(dynamic value) => value
      .toString()
      .replaceAllMapped(RegExp(r'#\s*(\d+)'), (match) => 'رقم ${match[1]}')
      .replaceAllMapped(RegExp(r'(\d+)\s*#'), (match) => 'رقم ${match[1]}')
      .replaceAll('#', ' - ');
}
