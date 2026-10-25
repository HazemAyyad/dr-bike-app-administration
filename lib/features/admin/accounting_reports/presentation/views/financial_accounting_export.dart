import 'dart:typed_data';
import 'accounting_report_pdf.dart';
import 'dart:convert';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../controllers/financial_accounting_controller.dart';

class FinancialAccountingExport {
  static Future<void> export(
      FinancialAccountingController c, String action) async {
    final name =
        'accounting_${c.type}_${DateTime.now().millisecondsSinceEpoch}';
    if (action == 'csv') {
      await _save(
          '$name.csv', Uint8List.fromList(utf8.encode('\uFEFF${buildCsv(c)}')));
      return;
    }
    final bytes = await buildPdf(c);
    if (action == 'share') {
      await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
    } else if (action == 'print') {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: '$name.pdf');
    } else {
      await _save('$name.pdf', bytes);
    }
  }

  static List<List<String>> data(FinancialAccountingController c) => [
        if (c.openingVisible) c.openingCells,
        ...c.rows.map(c.cells),
        c.totalCells,
      ];
  static String buildCsv(FinancialAccountingController c) {
    String cell(String value) {
      if (RegExp(r'^\s*[=+@-]').hasMatch(value) &&
          num.tryParse(value) == null) {
        value = "'$value";
      }
      return '"${value.replaceAll('"', '""')}"';
    }

    return [
      [c.title],
      [c.period, c.appliedCurrency],
      ...c.summaryCards.entries.map((e) => [e.key, e.value]),
      c.columns,
      ...data(c),
      ...c.notes.map((n) => [n]),
    ].map((row) => row.map(cell).join(',')).join('\r\n');
  }

  static AccountingReportDocument document(FinancialAccountingController c) {
    String label(
        List<Map<String, dynamic>> options, dynamic selected, String all) {
      if (selected == null || '$selected'.isEmpty) return all;
      for (final item in options) {
        if ('${item['key']}' == '$selected') return '${item['name']}';
      }
      return '$selected';
    }

    return AccountingReportDocument(
      kind: 'accounting_${c.type}',
      title: c.title,
      from: '${c.applied['from_date']}',
      to: '${c.applied['to_date']}',
      currency: c.appliedCurrency,
      columns: c.columns,
      rows: data(c),
      summary: c.summaryCards,
      notes: c.notes,
      selection: c.isExpenses
          ? 'المصروف: ${label(c.categories, c.applied['category_key'], 'الكل')} • الصندوق: ${label(c.boxes, c.applied['box_id'], 'الكل')} • الرصيد المدور: ${c.openingVisible ? 'محتسب' : 'غير محتسب'}'
          : 'جميع بنود الإيرادات والتكلفة والمصاريف خلال الفترة',
    );
  }

  static Future<Uint8List> buildPdf(FinancialAccountingController c) =>
      AccountingReportPdf.build(document(c));

  static Future<void> _save(String name, Uint8List bytes) async {
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final file =
        await File('${dir.path}/$name').writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }
}
