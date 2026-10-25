import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AccountingReportDocument {
  AccountingReportDocument({
    required this.kind,
    required this.title,
    required this.from,
    required this.to,
    required this.currency,
    required this.columns,
    required this.rows,
    required this.summary,
    required this.notes,
    required this.selection,
  }) : generatedAt = DateTime.now();
  final String kind;
  final String title;
  final String from;
  final String to;
  final String currency;
  final List<String> columns;
  final List<List<String>> rows;
  final Map<String, String> summary;
  final List<String> notes;
  final String selection;
  final DateTime generatedAt;
  PdfPageFormat get pageFormat =>
      columns.length > 6 ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
}

class AccountingReportPdf {
  static final brand = PdfColor.fromHex('#6B65BD');
  static final border = PdfColor.fromHex('#D1D5DB');

  static Future<Uint8List> build(AccountingReportDocument data) =>
      buildAll([data]);

  static Future<Uint8List> buildAll(
      List<AccountingReportDocument> reports) async {
    final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf'));
    final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf'));
    final logoBytes =
        await rootBundle.load('assets/images/purchase_invoice_logo.jpg');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final document = pw.Document();
    for (final data in reports) {
      // A new currency always starts on a fresh page, with its own heading/totals.
      var firstPage = 0;
      final date = data.generatedAt
          .toIso8601String()
          .substring(0, 16)
          .replaceFirst('T', ' ');
      document.addPage(pw.MultiPage(
        pageFormat: data.pageFormat,
        maxPages: 1000,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
            defaultTextStyle: pw.TextStyle(
                font: regular, fontSize: 10, color: PdfColors.grey900)),
        header: (context) {
          if (firstPage == 0) {
            firstPage = context.pageNumber;
          }
          return context.pageNumber == firstPage
              ? pw.SizedBox()
              : pw.Column(children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('تقارير محاسبية',
                            style: pw.TextStyle(font: bold, color: brand)),
                        pw.Text('${data.title} • ${data.currency}')
                      ]),
                  pw.Divider(color: border),
                ]);
        },
        footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: border))),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${context.pageNumber} / ${context.pagesCount}',
                      textDirection: pw.TextDirection.ltr,
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('تقارير محاسبية',
                      style: const pw.TextStyle(fontSize: 8)),
                ])),
        build: (_) => [
          // Same logo placement, QR size, color and type hierarchy as the maintenance invoice.
          pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(
                        width: 130,
                        height: 88,
                        child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Image(logo, height: 88))),
                    pw.Expanded(
                        child: pw.Center(
                            child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: jsonEncode({
                                  'type': data.kind,
                                  'from': data.from,
                                  'to': data.to,
                                  'currency': data.currency
                                }),
                                width: 64,
                                height: 64,
                                drawText: false))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('تقارير محاسبية',
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: bold, fontSize: 21, color: brand))),
                  ])),
          pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 10),
              height: 1.3,
              color: brand),
          pw.Center(
              child: pw.Text(data.title,
                  style: pw.TextStyle(font: bold, fontSize: 16))),
          pw.SizedBox(height: 8),
          pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: border),
                  borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('من: ${data.from}    إلى: ${data.to}'),
                    pw.SizedBox(height: 5),
                    pw.Text('العملة: ${data.currency}    تاريخ الطباعة: $date'),
                    pw.SizedBox(height: 5),
                    pw.Text(data.selection),
                  ])),
          pw.SizedBox(height: 10),
          pw.Wrap(spacing: 10, runSpacing: 6, children: [
            for (final item in data.summary.entries)
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F9FAFB'),
                    border: pw.Border.all(color: border)),
                child: pw.Text('${item.key}: ${item.value}',
                    style: pw.TextStyle(font: bold, fontSize: 9)),
              )
          ]),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: data.columns.reversed.toList(),
            data: data.rows.map((row) => row.reversed.toList()).toList(),
            headerStyle:
                pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
            cellStyle: const pw.TextStyle(fontSize: 8),
            // The header is row 0; the last data row contains the totals.
            cellDecoration: (_, __, row) => row == data.rows.length
                ? pw.BoxDecoration(color: PdfColor.fromHex('#E5E7EB'))
                : const pw.BoxDecoration(),
            textStyleBuilder: (_, __, row) => row == data.rows.length
                ? pw.TextStyle(
                    font: bold, fontSize: 8, color: PdfColors.grey900)
                : null,
            headerDecoration: pw.BoxDecoration(color: brand),
            oddRowDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#F9FAFB')),
            cellPadding: const pw.EdgeInsets.all(6),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: border, width: .5),
          ),
          pw.SizedBox(height: 12),
          for (final note in data.notes)
            pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(note, style: const pw.TextStyle(fontSize: 8))),
        ],
      ));
    }
    return document.save();
  }
}
