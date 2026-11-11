import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../widgets/unified_partner_selector.dart';
import '../../data/financial_accounting_api_service.dart';
import 'accounting_report_pdf.dart';
import 'accounting_report_preview.dart';

class PartyAccountStatementScreen extends StatefulWidget {
  const PartyAccountStatementScreen({Key? key, required this.service})
      : super(key: key);

  final FinancialAccountingApiService service;

  @override
  State<PartyAccountStatementScreen> createState() =>
      _PartyAccountStatementScreenState();
}

class _PartyAccountStatementScreenState
    extends State<PartyAccountStatementScreen> {
  final _money = NumberFormat('#,##0.00', 'en');
  List<Map<String, dynamic>> _people = [];
  Map<String, dynamic>? _selected;
  late DateTime _from;
  late DateTime _to;
  String _currency = 'شيكل';
  bool _opening = true;
  bool _checks = true;
  bool _loading = false;
  bool _exporting = false;
  bool _loadingPeople = true;
  String? _error;
  String? _peopleError;
  AccountingReportDocument? _document;

  bool get _busy => _loading || _exporting;
  String _date(DateTime date) => date.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(now.year, now.month);
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    setState(() {
      _loadingPeople = true;
      _peopleError = null;
    });
    try {
      final result = await widget.service.load('account-statement/people', {});
      final people = (result['people'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (mounted) setState(() => _people = people);
    } catch (_) {
      if (mounted) {
        setState(() => _peopleError = 'تعذر تحميل قائمة الزبائن والموردين.');
      }
    } finally {
      if (mounted) setState(() => _loadingPeople = false);
    }
  }

  void _clear() {
    _document = null;
    _error = null;
  }

  Future<void> _load() async {
    if (_busy) return;
    final person = _selected;
    if (person == null || _to.isBefore(_from)) {
      setState(() {
        _clear();
        _error = person == null
            ? 'اختر الزبون أو المورد أولًا.'
            : 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية أو بنفس اليوم.';
      });
      return;
    }
    setState(() {
      _clear();
      _loading = true;
    });
    try {
      final report = await widget.service.load('account-statement', {
        'person_type': person['type'],
        'person_id': person['id'],
        'from_date': _date(_from),
        'to_date': _date(_to),
        'currency': _currency,
        'include_opening': _opening ? 1 : 0,
        'include_returned_checks': _checks ? 1 : 0,
      });
      final document = _buildDocument(report);
      if (mounted) setState(() => _document = document);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر تحميل كشف الحساب. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AccountingReportDocument _buildDocument(Map<String, dynamic> report) {
    final filters = report['filters'] as Map;
    final summary = report['summary'] as Map;
    final person = report['person'] as Map;
    final checks = report['returned_checks'] as Map;
    String money(dynamic value) => _money.format(value as num);
    final rows = <List<String>>[
      if (filters['include_opening'] == true)
        [
          '0',
          'الرصيد المدور',
          '',
          '',
          '',
          money(summary['opening_balance']),
          ''
        ],
      for (final row in (report['rows'] as List).cast<Map>())
        [
          '${row['number']}',
          '${row['description']}',
          '${row['date']}',
          money(row['debit']),
          money(row['credit']),
          money(row['balance']),
          '${row['notes'] ?? ''}'
        ],
      [
        '',
        'الرصيد',
        '',
        money(summary['debit']),
        money(summary['credit']),
        money(summary['closing_balance']),
        ''
      ],
      if (filters['include_returned_checks'] == true) ...[
        [
          '',
          'الشيكات الواردة المرتجعة',
          '',
          money(checks['incoming']),
          '',
          money(summary['closing_balance']),
          'ملخص للعرض'
        ],
        [
          '',
          'الشيكات الصادرة المرتجعة',
          '',
          '',
          money(checks['outgoing']),
          money(summary['closing_balance']),
          'ملخص للعرض'
        ],
      ],
    ];
    final totalIndex =
        rows.length - (filters['include_returned_checks'] == true ? 3 : 1);
    return AccountingReportDocument(
      kind: 'party_account_statement',
      title: 'كشف حساب — ${person['name']}',
      from: '${filters['from_date']}',
      to: '${filters['to_date']}',
      currency: '${filters['currency']}',
      columns: const [
        'الرقم',
        'البيان',
        'التاريخ',
        'مدين',
        'دائن',
        'الرصيد',
        'ملاحظات'
      ],
      rows: rows,
      subtotalRows: {totalIndex, if (filters['include_opening'] == true) 0},
      summary: const {},
      notes: (report['notes'] as List).cast<String>(),
      selection:
          '${filters['person_type'] == 'seller' ? 'مورد' : 'زبون'} • ${person['phone'] ?? ''} • الرصيد المدور ${filters['include_opening'] == true ? 'محتسب' : 'غير محتسب'}',
    );
  }

  Future<void> _pickDate(bool from) async {
    final result = await showDatePicker(
        context: context,
        initialDate: from ? _from : _to,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (result == null || !mounted) return;
    setState(() {
      if (from) {
        _from = result;
      } else {
        _to = result;
      }
      _clear();
    });
  }

  Future<void> _export(String action) async {
    final document = _document;
    if (document == null || _busy) return;
    final render = context.findRenderObject();
    final bounds = render is RenderBox && render.hasSize
        ? render.localToGlobal(Offset.zero) & render.size
        : null;
    setState(() => _exporting = true);
    try {
      final name =
          '${document.kind}_${document.generatedAt.millisecondsSinceEpoch}';
      if (action == 'csv') {
        String cell(String value) {
          if (RegExp(r'^\s*[=+@-]').hasMatch(value) &&
              num.tryParse(value.replaceAll(',', '')) == null) {
            value = "'$value";
          }
          return '"${value.replaceAll('"', '""')}"';
        }

        final csv = [
          [document.title],
          [document.from, document.to, document.currency],
          document.columns,
          ...document.rows
        ].map((row) => row.map(cell).join(',')).join('\r\n');
        await _save('$name.csv', utf8.encode('\uFEFF$csv'));
      } else {
        final bytes = await AccountingReportPdf.build(document);
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
            const SnackBar(content: Text('تعذر تصدير كشف الحساب.')));
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

  @override
  Widget build(BuildContext context) {
    final document = _document;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('كشف حساب'), actions: [
          PopupMenuButton<String>(
              tooltip: 'تصدير كشف الحساب',
              enabled: !_busy && document != null,
              onSelected: _export,
              itemBuilder: (_) => const [
                    PopupMenuItem(value: 'download', child: Text('تنزيل PDF')),
                    PopupMenuItem(value: 'share', child: Text('مشاركة PDF')),
                    PopupMenuItem(value: 'print', child: Text('طباعة')),
                    PopupMenuItem(
                        value: 'csv', child: Text('تنزيل CSV لـ Excel')),
                  ]),
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
                            if (_loadingPeople) const LinearProgressIndicator(),
                            if (_peopleError != null)
                              TextButton(
                                  onPressed:
                                      _loadingPeople ? null : _loadPeople,
                                  child: Text('$_peopleError إعادة المحاولة')),
                            UnifiedPartnerSelector<Map<String, dynamic>>(
                              title: 'الحساب',
                              customers: _people
                                  .where((row) => row['type'] == 'customer')
                                  .toList(),
                              sellers: _people
                                  .where((row) => row['type'] == 'seller')
                                  .toList(),
                              selected: _selected,
                              selectedIsSeller: _selected?['type'] == 'seller',
                              idOf: (row) => row['id'] as int,
                              nameOf: (row) => '${row['name'] ?? ''}',
                              phoneOf: (row) => '${row['phone'] ?? ''}',
                              requiredSelection: true,
                              enabled: !_busy && !_loadingPeople,
                              onSelected: (person, _) => setState(() {
                                _selected = person;
                                _clear();
                              }),
                              onCleared: () => setState(() {
                                _selected = null;
                                _clear();
                              }),
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              for (final from in [true, false])
                                Expanded(
                                    child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: OutlinedButton(
                                      onPressed:
                                          _busy ? null : () => _pickDate(from),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(from
                                                ? 'من تاريخ'
                                                : 'إلى تاريخ'),
                                            FittedBox(
                                              child: Text(
                                                  _date(from ? _from : _to),
                                                  textDirection:
                                                      TextDirection.ltr),
                                            )
                                          ])),
                                ))
                            ]),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                                initialValue: _currency,
                                decoration:
                                    const InputDecoration(labelText: 'العملة'),
                                items: [
                                  for (final currency in [
                                    'شيكل',
                                    'دولار',
                                    'دينار'
                                  ])
                                    DropdownMenuItem(
                                        value: currency, child: Text(currency))
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
                                title: const Text('احتساب الرصيد المدور'),
                                value: _opening,
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(() {
                                          _opening = value;
                                          _clear();
                                        })),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title:
                                    const Text('إظهار ملخص الشيكات المرتجعة'),
                                value: _checks,
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(() {
                                          _checks = value;
                                          _clear();
                                        })),
                            FilledButton(
                                onPressed:
                                    _busy || _selected == null ? null : _load,
                                child: const Text('تطبيق وعرض الكشف')),
                          ]))),
              const SizedBox(height: 12),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (document != null)
                AccountingReportPreview(snapshot: document, document: document),
            ]),
          ),
        ),
      ),
    );
  }
}
