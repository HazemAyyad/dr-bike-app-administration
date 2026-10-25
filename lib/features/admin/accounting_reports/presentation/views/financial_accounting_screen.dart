import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/financial_accounting_controller.dart';
import 'financial_accounting_export.dart';
import 'accounting_report_preview.dart';

class FinancialAccountingScreen extends GetView<FinancialAccountingController> {
  const FinancialAccountingScreen({Key? key, required this.type})
      : super(key: key);
  final String type;
  @override
  String? get tag => type;

  @override
  Widget build(BuildContext context) =>
      GetBuilder<FinancialAccountingController>(
        tag: type,
        builder: (c) {
          final busy = c.loading || c.exporting;
          return Scaffold(
            appBar: AppBar(title: Text(c.title), actions: [
              PopupMenuButton<String>(
                tooltip: 'تصدير التقرير',
                enabled: !busy && c.report != null && !c.pending,
                onSelected: (v) async {
                  c.changed(() => c.exporting = true);
                  try {
                    await FinancialAccountingExport.export(c, v);
                  } catch (_) {
                    AppFailureNotice.show(
                        title: 'تعذر التصدير',
                        message: 'تعذر تجهيز التقرير. حاول مرة أخرى.');
                  } finally {
                    c.changed(() => c.exporting = false);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'download', child: Text('تنزيل PDF')),
                  PopupMenuItem(value: 'share', child: Text('مشاركة PDF')),
                  PopupMenuItem(value: 'print', child: Text('طباعة')),
                  PopupMenuItem(
                      value: 'csv', child: Text('تنزيل CSV لـ Excel')),
                ],
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ]),
            body: Directionality(
                textDirection: TextDirection.rtl,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: ListView(
                      key: const ValueKey('accounting-report-scroll'),
                      padding: const EdgeInsets.all(12),
                      children: [
                        _filters(context, c, busy),
                        if (busy)
                          const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator()),
                        if (c.error != null)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(children: [
                                    Text(c.error!),
                                    TextButton(
                                        onPressed: busy ? null : c.load,
                                        child: const Text('إعادة المحاولة')),
                                  ]))),
                        if (c.report != null) ...[
                          const SizedBox(height: 16),
                          Text(c.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('${c.period} • العملة: ${c.appliedCurrency}'),
                          if (c.pending)
                            const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                    'تغيّرت الفلاتر. اضغط تطبيق لتحديث النتائج.',
                                    style:
                                        TextStyle(color: Color(0xFF985300)))),
                          const SizedBox(height: 12),
                          if ((c.report!['quality']
                                  as Map?)?['cost_complete'] ==
                              false)
                            const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                    'بعض التكاليف التاريخية غير متوفرة؛ تعذر حساب الربح الكامل.',
                                    style:
                                        TextStyle(color: Color(0xFF985300)))),
                          AccountingReportPreview(
                              snapshot: c.report!,
                              document: FinancialAccountingExport.document(c)),
                          Card(
                              child: ExpansionTile(
                                  title: const Text('تفاصيل الحركات'),
                                  childrenPadding: const EdgeInsets.all(12),
                                  children: [
                                _summary(context, c),
                                const SizedBox(height: 12),
                                Text(
                                    c.isExpenses
                                        ? 'اضغط على الحركة لفتح تفاصيل السند • اسحب أفقيًا لعرض الأعمدة'
                                        : 'اضغط على بند مصروف لعرض حركاته لنفس الفترة',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 8),
                                _table(context, c),
                              ])),
                          const SizedBox(height: 12),
                          Card(
                              child: ExpansionTile(
                                  title:
                                      const Text('مصادر الأرقام وطريقة الحساب'),
                                  childrenPadding: const EdgeInsets.all(16),
                                  children: [
                                for (final note in c.notes)
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: Text(note))),
                              ])),
                        ],
                      ],
                    ),
                  ),
                )),
          );
        },
      );

  Widget _filters(
          BuildContext context, FinancialAccountingController c, bool busy) =>
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 800;
              final width =
                  wide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      for (final from in [true, false])
                        SizedBox(
                          width: wide ? width : (width - 12) / 2,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 18),
                            label: Column(children: [
                              Text(from ? 'من تاريخ' : 'إلى تاريخ'),
                              FittedBox(
                                  child: Text(
                                      FinancialAccountingController.date(
                                          from ? c.fromDate : c.toDate)))
                            ]),
                            onPressed: busy
                                ? null
                                : () async {
                                    final value = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            from ? c.fromDate : c.toDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100));
                                    if (value != null) {
                                      c.changed(() {
                                        if (from) {
                                          c.fromDate = value;
                                        } else {
                                          c.toDate = value;
                                        }
                                      });
                                    }
                                  },
                          ),
                        ),
                      SizedBox(
                          width: width,
                          child: _dropdown(
                              'العملة',
                              c.currency,
                              const {
                                'شيكل': 'شيكل',
                                'دولار': 'دولار',
                                'دينار': 'دينار'
                              },
                              busy
                                  ? null
                                  : (v) => c.changed(() {
                                        c.currency = v;
                                        c.categoryKey = '';
                                        c.boxId = '';
                                      }))),
                      if (c.isExpenses) ...[
                        SizedBox(
                            width: width,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.search),
                              label: Text(
                                  _selectedName(c.categories, c.categoryKey,
                                      'كل المصاريف'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final v = await _select(context,
                                          'اختيار المصروف', c.categories);
                                      if (v != null) {
                                        c.changed(() => c.categoryKey = v);
                                      }
                                    },
                            )),
                        SizedBox(
                            width: width,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.point_of_sale_outlined),
                              label: Text(
                                  _selectedName(
                                      c.boxes, c.boxId, 'كل الصناديق'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final v = await _select(
                                          context, 'اختيار الصندوق', c.boxes);
                                      if (v != null) {
                                        c.changed(() => c.boxId = v);
                                      }
                                    },
                            )),
                      ],
                    ]),
                    if (c.isExpenses)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('احتساب الرصيد المدور'),
                        value: c.includeOpening,
                        onChanged: busy
                            ? null
                            : (v) =>
                                c.changed(() => c.includeOpening = v ?? false),
                      ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('تذكّر خياراتي'),
                      value: c.remember,
                      onChanged: busy
                          ? null
                          : (v) async {
                              try {
                                await c.setRemember(v ?? false);
                              } catch (_) {
                                AppFailureNotice.show(
                                    title: 'تعذر الحفظ',
                                    message: 'تعذر حفظ خيارات التقرير');
                              }
                            },
                    ),
                    FilledButton.icon(
                        onPressed: busy ? null : c.load,
                        icon: const Icon(Icons.check),
                        label: const Text('تطبيق وعرض التقرير')),
                  ]);
            })),
      );

  Widget _dropdown(String label, String value, Map<String, String> options,
          ValueChanged<String>? changed) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: const OutlineInputBorder()),
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: changed == null
            ? null
            : (v) {
                if (v != null) changed(v);
              },
      );

  String _selectedName(
      List<Map<String, dynamic>> options, String selected, String all) {
    if (selected.isEmpty) return all;
    for (final option in options) {
      if ('${option['key']}' == selected) return '${option['name']}';
    }
    return 'اختيار محدد • تغيير';
  }

  Future<String?> _select(BuildContext context, String title,
      List<Map<String, dynamic>> options) async {
    String query = '';
    return showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF5F5F5),
        builder: (sheet) => Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                  child: Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, MediaQuery.viewInsetsOf(sheet).bottom + 12),
                child: SizedBox(
                    height: MediaQuery.sizeOf(sheet).height * .65,
                    child: StatefulBuilder(builder: (context, setState) {
                      final visible = options
                          .where((r) => '${r['name']}'.contains(query.trim()))
                          .toList();
                      return Column(children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                                hintText: 'ابحث بالاسم',
                                filled: true,
                                fillColor: Colors.white,
                                hintStyle: TextStyle(color: Colors.black54),
                                border: OutlineInputBorder()),
                            onChanged: (v) => setState(() => query = v)),
                        ListTile(
                            title: const Text('الكل',
                                style: TextStyle(color: Colors.black87)),
                            onTap: () => Navigator.pop(context, '')),
                        Expanded(
                            child: ListView.builder(
                                itemCount: visible.length,
                                itemBuilder: (_, i) => ListTile(
                                    title: Text('${visible[i]['name']}',
                                        style: const TextStyle(
                                            color: Colors.black87)),
                                    onTap: () => Navigator.pop(
                                        context, '${visible[i]['key']}')))),
                      ]);
                    })),
              )),
            ));
  }

  Widget _summary(BuildContext context, FinancialAccountingController c) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 800 ? 3 : 2;
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.summaryCards.entries
                .map((item) => SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 8) / columns,
                      child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.key,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                        child: Text(item.value,
                                            textDirection: TextDirection.ltr,
                                            style: const TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    AppColors.primaryColor))),
                                  ]))),
                    ))
                .toList());
      });

  Widget _table(BuildContext context, FinancialAccountingController c) {
    final rows = c.rows;
    Widget line(List<String> values,
            {bool header = false,
            bool total = false,
            VoidCallback? onTap,
            bool alternate = false}) =>
        Material(
          color: header
              ? AppColors.primaryColor
              : total
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : alternate
                      ? Theme.of(context).colorScheme.surfaceContainerLow
                      : Theme.of(context).colorScheme.surface,
          child: InkWell(
              onTap: onTap,
              child: Row(children: [
                for (var i = 0; i < values.length; i++)
                  SizedBox(
                      width: i == 0 || i == 1 ? 160 : 135,
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(values[i],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: num.tryParse(values[i]) != null
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: header ? Colors.white : null,
                                  fontWeight: header || total
                                      ? FontWeight.bold
                                      : FontWeight.normal)))),
              ])),
        );
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
            width: 320 + (c.columns.length - 2) * 135,
            child: Column(children: [
              line(c.columns, header: true),
              if (c.openingVisible) line(c.openingCells, total: true),
              if (rows.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('لا توجد حركات ضمن الفترة المختارة')),
              if (rows.isNotEmpty)
                SizedBox(
                    height: rows.length < 7 ? rows.length * 62.0 : 434,
                    child: ListView.builder(
                        itemExtent: 62,
                        itemCount: rows.length,
                        itemBuilder: (_, i) => line(
                              c.cells(rows[i]),
                              alternate: i.isOdd,
                              onTap: c.isExpenses &&
                                      rows[i]['detail_key'] != null
                                  ? () => _detail(
                                      context, c, '${rows[i]['detail_key']}')
                                  : !c.isExpenses &&
                                          rows[i]['section'] == 'expense'
                                      ? () => Get.toNamed(
                                          AppRoutes.EXPENSEACCOUNTINGSCREEN,
                                          arguments:
                                              c.expenseDrilldown(rows[i]))
                                      : null,
                            ))),
              line(c.totalCells, total: true),
            ])));
  }

  Future<void> _detail(
      BuildContext context, FinancialAccountingController c, String key) async {
    var future = c.service.detail(key);
    await showDialog<void>(
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, refresh) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  backgroundColor: const Color(0xFFF5F5F5),
                  title: const Text('تفاصيل الحركة',
                      style: TextStyle(color: Colors.black87)),
                  content: SizedBox(
                      width: 650,
                      child: FutureBuilder<Map<String, dynamic>>(
                          future: future,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('تعذر تحميل تفاصيل الحركة',
                                        style:
                                            TextStyle(color: Colors.black87)),
                                    TextButton(
                                        onPressed: () => refresh(() =>
                                            future = c.service.detail(key)),
                                        child: const Text('إعادة المحاولة'))
                                  ]);
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                  height: 120,
                                  child: Center(
                                      child: CircularProgressIndicator()));
                            }
                            final data = snapshot.data!;
                            return SingleChildScrollView(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Text('${data['title']}',
                                      style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold)),
                                  for (final field in c.maps(data['fields']))
                                    Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: SelectableText(
                                            '${field['label']}: ${field['value'] ?? '—'}',
                                            style: const TextStyle(
                                                color: Colors.black87))),
                                  for (final row in c.maps(data['lines']))
                                    Container(
                                        margin: const EdgeInsets.only(top: 10),
                                        padding: const EdgeInsets.all(10),
                                        color: Colors.white,
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('${row['account']}',
                                                  style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(
                                                  'مدين: ${FinancialAccountingController.amount(row['debit'])} • دائن: ${FinancialAccountingController.amount(row['credit'])}',
                                                  style: const TextStyle(
                                                      color: Colors.black87)),
                                              Text('الصندوق: ${row['box']}',
                                                  style: const TextStyle(
                                                      color: Colors.black87)),
                                              if (row['description'] != null)
                                                Text('${row['description']}',
                                                    style: const TextStyle(
                                                        color: Colors.black87)),
                                            ])),
                                ]));
                          })),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق'))
                  ],
                ))));
  }
}
