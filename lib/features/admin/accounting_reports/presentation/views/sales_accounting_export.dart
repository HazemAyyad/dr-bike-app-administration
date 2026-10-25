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

    return [
      [c.reportTitle],
      [c.period, 'العملة: ${c.report?['currency']}'],
      c.columns,
      ...c.rows.map(c.cells),
      c.cells(c.summary, total: true),
    ].map((row) => row.map(cell).join(',')).join('\r\n');
  }

  static AccountingReportDocument document(SalesAccountingController c) {
    final personKey = c.applied['person_key'] ?? '';
    final person = c.people.where((p) => p['key'] == personKey).toList();
    return AccountingReportDocument(
      kind: 'sales_accounting',
      title: c.reportTitle,
      from: '${c.applied['from_date']}',
      to: '${c.applied['to_date']}',
      currency: '${c.report?['currency']}',
      columns: c.columns,
      rows: [...c.rows.map(c.cells), c.cells(c.summary, total: true)],
      summary: {
        for (final item in c.activeSummaryCardsForDocument.entries)
          item.key: item.value
      },
      notes: c.notes,
      selection:
          'الحساب: ${personKey == '' ? 'كل الزبائن والأطراف' : person.isNotEmpty ? person.first['name'] : personKey} • المرتجعات: ${c.returnsVisible ? 'محتسبة' : 'غير محتسبة'}',
    );
  }

  static Future<Uint8List> buildPdf(SalesAccountingController c) =>
      AccountingReportPdf.build(document(c));

  static Future<File> _save(String name, Uint8List bytes) async {
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/$name').writeAsBytes(bytes, flush: true);
  }
}
