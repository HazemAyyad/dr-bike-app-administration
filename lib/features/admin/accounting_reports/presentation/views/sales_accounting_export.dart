import 'dart:typed_data';
import 'accounting_report_pdf.dart';
import 'dart:convert';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../controllers/sales_accounting_controller.dart';

class SalesAccountingExport {
  static Future<void> export(SalesAccountingController c, String action) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    if (action == 'csv') {
      final csv = buildCsv(c);
      final file = await _save('sales_accounting_$stamp.csv',
          Uint8List.fromList(utf8.encode('\uFEFF$csv')));
      await OpenFilex.open(file.path);
      return;
    }
    final bytes = await buildPdf(c);
    final name = 'sales_accounting_$stamp.pdf';
    if (action == 'share') {
      await Printing.sharePdf(bytes: bytes, filename: name);
    } else if (action == 'print') {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
    } else {
      final file = await _save(name, bytes);
      await OpenFilex.open(file.path);
    }
  }

  static String buildCsv(SalesAccountingController c) {
    String cell(String value) {
      // Account names are data, including names that Excel could interpret as formulas.
      if (RegExp(r'^[\s]*[=+@-]').hasMatch(value) &&
          num.tryParse(value.replaceAll('%', '')) == null) {
        value = "'$value";
      }
      return '"${value.replaceAll('"', '""')}"';
    }

    final reports = documents(c);
    return [
      [c.reportTitle],
      [c.period],
      [reports.first.selection],
      for (final report in reports) ...[
        ['العملة: ${report.currency}'],
        report.columns,
        ...report.rows,
        [''],
      ],
    ].map((row) => row.map(cell).join(',')).join('\r\n');
  }

  static AccountingReportDocument document(SalesAccountingController c) =>
      documents(c).first;

  static List<AccountingReportDocument> documents(
          SalesAccountingController c) =>
      c.currencyReports.map((section) => _document(c, section)).toList();

  static AccountingReportDocument _document(
      SalesAccountingController c, Map<String, dynamic> section) {
    final personKey = c.applied['person_key'] ?? '';
    final person = c.people.where((p) => p['key'] == personKey).toList();
    final representative = c.representatives
        .where((p) => '${p['key']}' == '${c.applied['representative_id']}')
        .toList();
    final rows = c.rowsFor(section);
    final summary = c.summaryFor(section);
    return AccountingReportDocument(
      kind: 'sales_accounting',
      title: c.reportTitle,
      from: '${c.applied['from_date']}',
      to: '${c.applied['to_date']}',
      currency: '${section['currency']}',
      columns: c.columns,
      rows: [
        for (var i = 0; i < rows.length; i++) c.cells(rows[i], sequence: i + 1),
        c.cells(summary, total: true)
      ],
      summary: c.summaryCards(summary),
      notes: c.notes,
      selection:
          'الحساب: ${personKey == '' ? 'كل الزبائن والأطراف' : person.isNotEmpty ? person.first['name'] : personKey} • المرتجعات: ${c.returnsVisible ? 'محتسبة' : 'غير محتسبة'}'
          '${c.applied['min_amount'] != null ? ' • من قيمة: ${c.applied['min_amount']}' : ''}'
          '${c.applied['max_amount'] != null ? ' • إلى قيمة: ${c.applied['max_amount']}' : ''}'
          ' • نقدي: ${c.applied['cash_only'] == true ? 'نعم' : 'لا'}'
          ' • المندوب: ${representative.isNotEmpty ? representative.first['name'] : '${c.applied['representative_id'] ?? ''}'.isEmpty ? 'كل موظفي المبيعات' : 'موظف #${c.applied['representative_id']}'}',
      // Each document contains one currency; there is no cross-currency total.
    );
  }

  static Future<Uint8List> buildPdf(SalesAccountingController c) =>
      AccountingReportPdf.buildAll(documents(c));

  static Future<File> _save(String name, Uint8List bytes) async {
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/$name').writeAsBytes(bytes, flush: true);
  }
}
