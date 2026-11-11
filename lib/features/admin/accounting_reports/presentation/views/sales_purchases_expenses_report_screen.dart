import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../data/financial_accounting_api_service.dart';
import 'accounting_report_pdf.dart';
import 'accounting_report_preview.dart';

enum _ReportView { daily, total }

enum _Export { download, share, print }

class SalesPurchasesExpensesReportScreen extends StatefulWidget {
  const SalesPurchasesExpensesReportScreen({Key? key, required this.service})
      : super(key: key);

  static const title = 'تقرير المبيعات والمشتريات والمصاريف';
  final FinancialAccountingApiService service;

  @override
  State<SalesPurchasesExpensesReportScreen> createState() =>
      _SalesPurchasesExpensesReportScreenState();
}

class _SalesPurchasesExpensesReportScreenState
    extends State<SalesPurchasesExpensesReportScreen> {
  static const _columns = {
    'sales': 'المبيعات',
    'purchases': 'المشتريات',
    'expenses': 'المصاريف',
  };
  static const _viewLabels = {
    _ReportView.daily: 'تفصيل يومي',
    _ReportView.total: 'إجمالي الفترة',
  };
  final _amountFormat = NumberFormat('#,##0.00', 'en');
  late DateTime _from;
  late DateTime _to;
  String _currency = 'شيكل';
  _ReportView _view = _ReportView.daily;
  bool _loading = false;
  bool _exporting = false;
  String? _error;
  Map<String, dynamic>? _report;
  AccountingReportDocument? _document;

  bool get _busy => _loading || _exporting;

  String _date(DateTime value) => value.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _to = DateTime.now();
    _from = DateTime(_to.year, _to.month);
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    final from = _date(_from);
    final to = _date(_to);
    setState(() {
      _report = null;
      _document = null;
      _error = _from.isAfter(_to)
          ? 'تاريخ البداية لازم يكون قبل تاريخ النهاية أو بنفس اليوم.'
          : null;
      _loading = _error == null;
    });
    if (!_loading) return;

    try {
      final report = await widget.service.load('sales-purchases-expenses', {
        'from_date': from,
        'to_date': to,
        'currency': _currency,
      });
      if (!mounted) return;
      final document = _buildDocument(report);
      setState(() {
        _report = report;
        _document = document;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر تحميل التقرير. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AccountingReportDocument _buildDocument(Map<String, dynamic> report) {
    final filters = report['filters'] as Map;
    final summary = report['summary'] as Map;
    final from = filters['from_date'] as String;
    final to = filters['to_date'] as String;
    String amount(Map row, String key) => _amountFormat.format(row[key] as num);
    List<String> cells(String label, Map row) => [
          label,
          for (final key in _columns.keys) amount(row, key),
        ];

    return AccountingReportDocument(
      kind: 'sales_purchases_expenses',
      title: SalesPurchasesExpensesReportScreen.title,
      from: from,
      to: to,
      currency: filters['currency'] as String,
      columns: [
        if (_view == _ReportView.daily) 'التاريخ' else 'الفترة',
        ..._columns.values
      ],
      rows: _view == _ReportView.daily
          ? [
              for (final row in (report['rows'] as List).cast<Map>())
                cells(row['date'] as String, row),
              cells('الإجمالي', summary),
            ]
          : [cells('$from إلى $to', summary)],
      summary: const {},
      notes: (report['notes'] as List).cast<String>(),
      selection: _viewLabels[_view]!,
    );
  }

  Future<void> _pickDate(bool start) async {
    final date = await showDatePicker(
      context: context,
      initialDate: start ? _from : _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (start) {
        _from = date;
      } else {
        _to = date;
      }
      _clearResult();
    });
  }

  void _clearResult() {
    _report = null;
    _document = null;
    _error = null;
  }

  Future<void> _export(_Export action) async {
    final document = _document;
    if (document == null || _busy) return;
    final render = context.findRenderObject();
    final bounds = render is RenderBox && render.hasSize
        ? render.localToGlobal(Offset.zero) & render.size
        : null;
    setState(() => _exporting = true);
    try {
      final bytes = await AccountingReportPdf.build(document);
      final stamp = document.generatedAt.millisecondsSinceEpoch;
      final name = '${document.kind}_$stamp.pdf';
      switch (action) {
        case _Export.download:
          final folder = await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          await folder.create(recursive: true);
          final file =
              await File('${folder.path}${Platform.pathSeparator}$name')
                  .writeAsBytes(bytes, flush: true);
          await OpenFilex.open(file.path);
          break;
        case _Export.share:
          await Printing.sharePdf(bytes: bytes, filename: name, bounds: bounds);
          break;
        case _Export.print:
          await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تصدير التقرير. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _dateButton(bool start) => OutlinedButton(
        onPressed: _busy ? null : () => _pickDate(start),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(start ? 'من تاريخ' : 'إلى تاريخ'),
            Text(_date(start ? _from : _to), textDirection: TextDirection.ltr),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final document = _document;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(SalesPurchasesExpensesReportScreen.title,
              maxLines: 2, style: Theme.of(context).textTheme.titleMedium),
          actions: [
            PopupMenuButton<_Export>(
              enabled: !_busy && document != null,
              tooltip: 'تصدير التقرير',
              onSelected: _export,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: _Export.download, child: Text('تنزيل PDF')),
                PopupMenuItem(value: _Export.share, child: Text('مشاركة PDF')),
                PopupMenuItem(value: _Export.print, child: Text('طباعة')),
              ],
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(child: _dateButton(true)),
                          const SizedBox(width: 8),
                          Expanded(child: _dateButton(false)),
                        ]),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<_ReportView>(
                          initialValue: _view,
                          decoration:
                              const InputDecoration(labelText: 'طريقة العرض'),
                          items: [
                            for (final entry in _viewLabels.entries)
                              DropdownMenuItem(
                                  value: entry.key, child: Text(entry.value)),
                          ],
                          onChanged: _busy
                              ? null
                              : (view) {
                                  if (view == null || view == _view) return;
                                  setState(() {
                                    _view = view;
                                    final report = _report;
                                    if (report != null) {
                                      _document = _buildDocument(report);
                                    }
                                  });
                                },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration:
                              const InputDecoration(labelText: 'العملة'),
                          items: const [
                            DropdownMenuItem(
                                value: 'شيكل', child: Text('شيكل')),
                            DropdownMenuItem(
                                value: 'دولار', child: Text('دولار')),
                            DropdownMenuItem(
                                value: 'دينار', child: Text('دينار')),
                          ],
                          onChanged: _busy
                              ? null
                              : (currency) {
                                  if (currency == null ||
                                      currency == _currency) {
                                    return;
                                  }
                                  setState(() {
                                    _currency = currency;
                                    _clearResult();
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _busy ? null : _load,
                            child: const Text('تطبيق وعرض التقرير')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                if (document != null)
                  AccountingReportPreview(
                      snapshot: document, document: document),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
