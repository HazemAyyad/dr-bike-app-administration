import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../data/financial_accounting_api_service.dart';
import 'accounting_report_pdf.dart';
import 'accounting_report_preview.dart';

class SalesProfitReportScreen extends StatefulWidget {
  const SalesProfitReportScreen({Key? key, required this.service})
      : super(key: key);
  static const title = 'تقرير أرباح المبيعات';
  final FinancialAccountingApiService service;

  @override
  State<SalesProfitReportScreen> createState() =>
      _SalesProfitReportScreenState();
}

class _SalesProfitReportScreenState extends State<SalesProfitReportScreen> {
  static const _sources = {
    'all': 'الكل',
    'sale': 'المبيعات',
    'order': 'الطلبيات',
    'maintenance': 'الصيانة',
    'profit_sale': 'البيع الربحي',
    'stock': 'سحوبات أخرى',
  };
  final _money = NumberFormat('#,##0.00', 'en');
  final _cost = NumberFormat('#,##0.######', 'en');
  final _quantity = NumberFormat('#,##0.###', 'en');
  late DateTime _from;
  late DateTime _to;
  String _currency = 'شيكل';
  String _source = 'all';
  bool _detail = false;
  bool _returns = true;
  bool _withdrawals = true;
  bool _loading = false;
  bool _exporting = false;
  String? _error;
  Map<String, dynamic>? _report;
  List<AccountingReportDocument> _documents = [];
  bool get _busy => _loading || _exporting;
  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
  String _amount(dynamic value) => value is num ? _money.format(value) : '—';
  String _precise(dynamic value) => value is num ? _cost.format(value) : '—';
  String _percent(dynamic value) =>
      value is num ? '${_money.format(value)}%' : '—';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(now.year, now.month);
    _load();
  }

  void _clear() {
    _report = null;
    _documents = [];
    _error = null;
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _clear();
      _error = _to.isBefore(_from)
          ? 'تاريخ النهاية يجب أن يكون بعد البداية أو بنفس اليوم.'
          : null;
      _loading = _error == null;
    });
    if (!_loading) return;
    try {
      final report = await widget.service.load('sales-profit', {
        'from_date': _date(_from),
        'to_date': _date(_to),
        'currency': _currency,
        'source': _source,
        'include_returns': _returns ? 1 : 0,
      });
      if (mounted) {
        setState(() {
          _report = report;
          _rebuild();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر تحميل تقرير الأرباح. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _rebuild() {
    final report = _report;
    if (report == null) return;
    final filters = report['filters'] as Map;
    final summary = report['summary'] as Map;
    final documents = (report['documents'] as List).cast<Map>();
    final rows = <List<String>>[];
    for (final doc in documents) {
      if (_detail) {
        for (final line in (doc['lines'] as List).cast<Map>()) {
          rows.add([
            '${doc['number']}',
            '${doc['date']}',
            '${doc['type']}',
            '${line['product_code']}',
            '${line['product']}',
            _quantity.format(line['quantity']),
            _quantity.format(line['bonus']),
            _precise(line['unit_cost']),
            _precise(line['price']),
            _amount(line['discount']),
            '${line['unit']}',
            _amount(line['profit']),
            _percent(line['profit_percent']),
          ]);
        }
      } else {
        rows.add([
          '${doc['number']}',
          '${doc['date']}',
          '${doc['type']}',
          _precise(doc['cost_total']),
          _amount((doc['sales_total'] as num) + (doc['discount'] as num)),
          _amount(doc['discount']),
          _amount(doc['profit']),
          _percent(doc['profit_percent'])
        ]);
      }
    }
    rows.add(_detail
        ? [
            'الإجمالي',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            _amount(summary['discount']),
            '',
            _amount(summary['profit']),
            _percent(summary['profit_percent'])
          ]
        : [
            '${summary['document_count']}',
            '',
            'الإجمالي',
            _precise(summary['cost_total']),
            _amount(
                (summary['sales_total'] as num) + (summary['discount'] as num)),
            _amount(summary['discount']),
            _amount(summary['profit']),
            _percent(summary['profit_percent'])
          ]);
    final selection =
        '${_sources[filters['source']]} • ${_detail ? 'تفصيلي حسب أصناف الفاتورة' : 'إجمالي حسب الفاتورة'} • ${filters['include_returns'] == true ? 'مع المرتجعات' : 'بدون المرتجعات'}';
    _documents = [
      AccountingReportDocument(
        kind: 'sales_profit_${_detail ? 'detail' : 'total'}',
        title:
            '${SalesProfitReportScreen.title} - ${_detail ? 'تفصيلي' : 'إجمالي'}',
        from: '${filters['from_date']}',
        to: '${filters['to_date']}',
        currency: '${filters['currency']}',
        columns: _detail
            ? [
                'الرقم',
                'التاريخ',
                'نوع السند',
                'رقم الصنف',
                'اسم الصنف',
                'الكمية',
                'بونص',
                'سعر التكلفة',
                'السعر',
                'الخصم',
                'الوحدة',
                'الربح',
                'نسبة الربح'
              ]
            : [
                'الرقم',
                'التاريخ',
                'نوع السند',
                'سعر التكلفة',
                'السعر',
                'الخصم في الفاتورة',
                'الربح',
                'نسبة الربح'
              ],
        rows: rows,
        subtotalRows: {rows.length - 1},
        summary: {
          'عدد المستندات': '${summary['document_count']}',
          'البيع بعد الخصم والمرتجعات': _amount(summary['sales_total']),
          'تكلفة المبيعات': _amount(summary['cost_total']),
          'إجمالي الربح قبل المصاريف': _amount(summary['profit']),
          'نسبة الربح على التكلفة': _percent(summary['profit_percent'])
        },
        notes: (report['notes'] as List).cast<String>(),
        selection: selection,
      )
    ];
    final withdrawals = (report['withdrawals'] as List).cast<Map>();
    if (_withdrawals && withdrawals.isNotEmpty) {
      _documents.add(AccountingReportDocument(
        kind: 'unbilled_withdrawals',
        title: 'سحوبات مخزون خارج إجمالي الأرباح',
        from: '${filters['from_date']}',
        to: '${filters['to_date']}',
        currency: 'شيكل',
        columns: [
          'الرقم',
          'التاريخ',
          'نوع الحركة',
          'رقم الصنف',
          'اسم الصنف',
          'الكمية',
          'التكلفة',
          'ملاحظات'
        ],
        rows: [
          for (final row in withdrawals)
            [
              '${row['number']}',
              '${row['date']}',
              '${row['type']}',
              '${row['product_code']}',
              '${row['product']}',
              _quantity.format(row['quantity']),
              _amount(row['cost_total']),
              '${row['note'] ?? ''}'
            ]
        ],
        summary: const {},
        selection: '${_sources[filters['source']]} • لا تُحتسب كمبيعات',
        notes: const [
          'حركات سحب مخزون لا يمثلها مستند بيع معتمد. تشمل سحوبات غير مفوترة وحركات داخلية وتسويات؛ لا يوجد سعر بيع معتمد لاحتساب ربحها.',
          'الحركات حسب تاريخ السحب، ولا تمثل رصيد مخزون حاليًا. لا تُضاف تكلفتها مرة أخرى إلى إجمالي أرباح المبيعات.'
        ],
      ));
    }
  }

  Future<void> _pickDate(bool start) async {
    final value = await showDatePicker(
        context: context,
        initialDate: start ? _from : _to,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (!mounted || value == null) return;
    setState(() {
      if (start) {
        _from = value;
      } else {
        _to = value;
      }
      _clear();
    });
  }

  Future<void> _export(String action) async {
    if (_busy || _documents.isEmpty) return;
    final documents = List<AccountingReportDocument>.of(_documents);
    final render = context.findRenderObject();
    final bounds = render is RenderBox && render.hasSize
        ? render.localToGlobal(Offset.zero) & render.size
        : null;
    setState(() => _exporting = true);
    try {
      final name =
          '${documents.first.kind}_${documents.first.generatedAt.millisecondsSinceEpoch}';
      if (action == 'csv') {
        String cell(String value) {
          if (RegExp(r'^\s*[=+@-]').hasMatch(value) &&
              num.tryParse(value.replaceAll(',', '')) == null) {
            value = "'$value";
          }
          return '"${value.replaceAll('"', '""')}"';
        }

        final lines = <List<String>>[];
        for (final document in documents) {
          lines.addAll([
            [document.title],
            [document.from, document.to, document.currency],
            document.columns,
            ...document.rows,
            []
          ]);
        }
        await _save(
            '$name.csv',
            utf8.encode(
                '\uFEFF${lines.map((row) => row.map(cell).join(',')).join('\r\n')}'));
      } else {
        final bytes = await AccountingReportPdf.buildAll(documents);
        if (action == 'share') {
          await Printing.sharePdf(
              bytes: bytes, filename: '$name.pdf', bounds: bounds);
        } else if (action == 'print') {
          await Printing.layoutPdf(
              onLayout: (_) async => bytes, name: '$name.pdf');
        } else {
          await _save('$name.pdf', bytes);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تصدير تقرير الأرباح.')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _save(String name, List<int> bytes) async {
    final folder = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    await folder.create(recursive: true);
    final file = await File('${folder.path}${Platform.pathSeparator}$name')
        .writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }

  Widget _dateButton(bool start) => OutlinedButton(
      onPressed: _busy ? null : () => _pickDate(start),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(start ? 'من تاريخ' : 'إلى تاريخ'),
        FittedBox(
            child: Text(_date(start ? _from : _to),
                textDirection: TextDirection.ltr))
      ]));

  @override
  Widget build(BuildContext context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar:
            AppBar(title: const Text(SalesProfitReportScreen.title), actions: [
          PopupMenuButton<String>(
              tooltip: 'تصدير تقرير الأرباح',
              enabled: !_busy && _documents.isNotEmpty,
              onSelected: _export,
              itemBuilder: (_) => const [
                    PopupMenuItem(value: 'download', child: Text('تنزيل PDF')),
                    PopupMenuItem(value: 'share', child: Text('مشاركة PDF')),
                    PopupMenuItem(value: 'print', child: Text('طباعة')),
                    PopupMenuItem(
                        value: 'csv', child: Text('تنزيل CSV لـ Excel'))
                  ])
        ]),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(padding: const EdgeInsets.all(12), children: [
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
                                Expanded(child: _dateButton(false))
                              ]),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<bool>(
                                  isExpanded: true,
                                  initialValue: _detail,
                                  decoration: const InputDecoration(
                                      labelText: 'طريقة العرض'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: false,
                                        child: Text('إجمالي حسب الفاتورة')),
                                    DropdownMenuItem(
                                        value: true,
                                        child:
                                            Text('تفصيلي حسب أصناف الفاتورة'))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              _detail = value;
                                              _rebuild();
                                            });
                                          }
                                        }),
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _source,
                                  decoration: const InputDecoration(
                                      labelText: 'مصدر العملية'),
                                  items: [
                                    for (final entry in _sources.entries)
                                      DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(entry.value))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              _source = value;
                                              _clear();
                                            });
                                          }
                                        }),
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _currency,
                                  decoration: const InputDecoration(
                                      labelText: 'العملة'),
                                  items: [
                                    for (final currency in [
                                      'شيكل',
                                      'دولار',
                                      'دينار'
                                    ])
                                      DropdownMenuItem(
                                          value: currency,
                                          child: Text(currency))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              _currency = value;
                                              _clear();
                                            });
                                          }
                                        }),
                              SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('احتساب المرتجعات'),
                                  value: _returns,
                                  onChanged: _busy
                                      ? null
                                      : (value) => setState(() {
                                            _returns = value;
                                            _clear();
                                          })),
                              SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title:
                                      const Text('إظهار السحوبات غير المفوترة'),
                                  value: _withdrawals,
                                  onChanged: _busy
                                      ? null
                                      : (value) => setState(() {
                                            _withdrawals = value;
                                            _rebuild();
                                          })),
                              FilledButton(
                                  onPressed: _busy ? null : _load,
                                  child: const Text('تطبيق وعرض التقرير')),
                            ]))),
                const SizedBox(height: 12),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                if ((_report?['summary']?['missing_cost_count'] ?? 0) > 0)
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'تكلفة بعض العمليات غير مكتملة؛ تظهر أرباحها وإجمالي الربح — لحين استكمال التكلفة.')),
                for (final document in _documents)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AccountingReportPreview(
                          key: ValueKey(document.kind),
                          snapshot: document,
                          document: document)),
              ])),
        ),
      ));
}
