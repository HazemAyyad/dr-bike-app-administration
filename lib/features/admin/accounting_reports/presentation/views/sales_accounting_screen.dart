import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_accounting_controller.dart';
import 'sales_accounting_export.dart';
import 'accounting_report_preview.dart';

class SalesAccountingScreen extends GetView<SalesAccountingController> {
  const SalesAccountingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => GetBuilder<SalesAccountingController>(
        builder: (c) {
          final busy = c.isLoading || c.isExporting;
          return Scaffold(
            appBar: AppBar(
              title: const Text('تقارير محاسبية'),
              actions: [
                IconButton(
                  tooltip: 'مشاركة التقرير المعروض',
                  onPressed: !busy && c.report != null
                      ? () => _export(c, 'share')
                      : null,
                  icon: const Icon(Icons.ios_share_outlined),
                ),
                PopupMenuButton<String>(
                  tooltip: 'تصدير التقرير',
                  enabled: !busy && c.report != null,
                  onSelected: (action) => _export(c, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'download', child: Text('تنزيل PDF')),
                    PopupMenuItem(value: 'share', child: Text('مشاركة PDF')),
                    PopupMenuItem(value: 'print', child: Text('طباعة')),
                    PopupMenuItem(
                        value: 'csv', child: Text('تنزيل CSV لـ Excel')),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
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
                      Text('إجمالي المبيعات',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                          'قارن المبيعات حسب الزبائن أو الأشهر أو الأيام.'),
                      const SizedBox(height: 12),
                      _filters(context, c, busy),
                      if (c.isLoading || c.isExporting) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                      if (c.error != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              Text(c.error!, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: busy ? null : c.load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ]),
                          ),
                        ),
                      ],
                      if (c.report != null) ...[
                        const SizedBox(height: 16),
                        Text(c.reportTitle,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${c.period}   •   العملة: ${c.currencyLabel}'),
                        if (c.hasPendingFilters)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                'تغيّرت خيارات التقرير. اضغط تطبيق لتحديث النتائج.',
                                style: TextStyle(color: Color(0xFF985300))),
                          ),
                        const SizedBox(height: 12),
                        AccountingReportPreview(
                            snapshot: c.report!,
                            document: SalesAccountingExport.document(c),
                            documents: SalesAccountingExport.documents(c)),
                        Card(
                            child: ExpansionTile(
                          title: const Text('تفاصيل الحركات'),
                          childrenPadding: const EdgeInsets.all(12),
                          children: [
                            for (final section in c.currencyReports) ...[
                              Text('العملة: ${section['currency']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _summary(context, c,
                                  summaryOverride: c.summaryFor(section)),
                              const SizedBox(height: 12),
                              if (c.rowsFor(section).isEmpty)
                                const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                        'لا توجد حركات ضمن الفترة المختارة'))
                              else
                                _SalesTable(controller: c, section: section),
                              const SizedBox(height: 20),
                            ],
                          ],
                        )),
                        const SizedBox(height: 12),
                        Card(
                          child: ExpansionTile(
                            title: const Text('كيف تُحسب الأرقام والنسب؟'),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: c.notes
                                .map((note) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Text(note),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _filters(
          BuildContext context, SalesAccountingController c, bool busy) =>
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fieldWidth = width >= 800 ? (width - 24) / 3 : width;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('طريقة عرض التقرير',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    for (final item in SalesAccountingController.groups.entries)
                      ChoiceChip(
                          label: Text(item.value),
                          selected: c.groupBy == item.key,
                          onSelected:
                              busy ? null : (_) => c.selectGroup(item.key)),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    SizedBox(
                      width: fieldWidth,
                      child: _dropdown(
                        label: 'العملة',
                        value: c.currency,
                        options: SalesAccountingController.currencies,
                        onChanged: busy
                            ? null
                            : (v) => c.changed(() => c.currency = v),
                      ),
                    ),
                    SizedBox(
                      width: width >= 800 ? fieldWidth : (width - 12) / 2,
                      child: OutlinedButton.icon(
                        onPressed:
                            busy ? null : () => _pickDate(context, c, true),
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Column(children: [
                          const Text('من تاريخ'),
                          FittedBox(
                              child: Text(
                                  SalesAccountingController.date(c.fromDate))),
                        ]),
                      ),
                    ),
                    SizedBox(
                      width: width >= 800 ? fieldWidth : (width - 12) / 2,
                      child: OutlinedButton.icon(
                        onPressed:
                            busy ? null : () => _pickDate(context, c, false),
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Column(children: [
                          const Text('إلى تاريخ'),
                          FittedBox(
                              child: Text(
                                  SalesAccountingController.date(c.toDate))),
                        ]),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : () => _pickPerson(context, c),
                        icon: const Icon(Icons.person_search_outlined),
                        label: Text(_personLabel(c),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    SizedBox(
                        width: fieldWidth,
                        child: OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () =>
                                  _pickPerson(context, c, representative: true),
                          icon: const Icon(Icons.badge_outlined),
                          label: Text(_representativeLabel(c),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                    SizedBox(
                      width: fieldWidth,
                      child: _dropdown(
                        label: 'الترتيب',
                        value: c.sort,
                        options: SalesAccountingController.sorts,
                        onChanged:
                            busy ? null : (v) => c.changed(() => c.sort = v),
                      ),
                    ),
                    for (final minimum in [true, false])
                      SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            initialValue: minimum ? c.minAmount : c.maxAmount,
                            enabled: !busy,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                                labelText: minimum ? 'من قيمة' : 'إلى قيمة',
                                helperText: 'قيمة الفاتورة / المرتجع',
                                border: const OutlineInputBorder(),
                                isDense: true),
                            onChanged: (v) => c.changed(() {
                              if (minimum) {
                                c.minAmount = v;
                              } else {
                                c.maxAmount = v;
                              }
                            }),
                          )),
                  ]),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('عرض الحركات بالعملات الأخرى'),
                    subtitle:
                        const Text('كشف وإجماليات مستقلة لكل عملة، بدون تحويل'),
                    value: c.includeOtherCurrencies,
                    onChanged: busy
                        ? null
                        : (v) => c.changed(
                            () => c.includeOtherCurrencies = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('نقدي'),
                    subtitle: const Text(
                        'فواتير مدفوعة بالكامل ومرتجعات مستردة نقدًا بالكامل'),
                    value: c.cashOnly,
                    onChanged: busy
                        ? null
                        : (v) => c.changed(() => c.cashOnly = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('احتساب مردودات المبيعات'),
                    value: c.includeReturns,
                    onChanged: busy ? null : (v) => c.selectReturns(v ?? false),
                  ),
                  const Divider(),
                  _columns(c, busy),
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
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: busy ? null : c.load,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('تطبيق وعرض التقرير'),
                  ),
                ]);
          }),
        ),
      );

  Widget _columns(SalesAccountingController c, bool busy) => ExpansionTile(
        key: const ValueKey('sales-report-column-picker'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: const Text('أعمدة التقرير',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${c.selectedColumnCount} من ${c.availableColumns.length} أعمدة • اختر عمودًا واحدًا على الأقل'),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: busy ? null : c.selectAllColumns,
              icon: const Icon(Icons.select_all),
              label: const Text('عرض كل الأعمدة'),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              for (final item in c.availableColumns.entries)
                FilterChip(
                  key: ValueKey('sales-report-column-${item.key}'),
                  label: Text(item.value),
                  selected: c.isColumnSelected(item.key),
                  onSelected: busy ||
                          (c.isColumnSelected(item.key) &&
                              c.selectedColumnCount == 1)
                      ? null
                      : (value) => c.selectColumn(item.key, value),
                ),
            ]),
          ),
        ],
      );

  Widget _dropdown(
          {required String label,
          required String value,
          required Map<String, String> options,
          ValueChanged<String>? onChanged}) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true),
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged == null
            ? null
            : (v) {
                if (v != null) onChanged(v);
              },
      );

  Future<void> _pickDate(
      BuildContext context, SalesAccountingController c, bool from) async {
    final value = await showDatePicker(
      context: context,
      initialDate: from ? c.fromDate : c.toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null) {
      c.changed(() {
        if (from) {
          c.fromDate = value;
        } else {
          c.toDate = value;
        }
      });
    }
  }

  String _personLabel(SalesAccountingController c) {
    if (c.personKey.isEmpty) return 'كل الزبائن والأطراف';
    for (final person in c.people) {
      if (person['key'] == c.personKey) return '${person['name']}';
    }
    return 'حساب محدد • تغيير';
  }

  Future<void> _pickPerson(BuildContext context, SalesAccountingController c,
      {bool representative = false}) async {
    String query = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F5F5),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 12),
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * .65,
              child: StatefulBuilder(builder: (context, setState) {
                final people = (representative ? c.representatives : c.people)
                    .where((p) => '${p['name']}'.contains(query.trim()))
                    .toList();
                return Column(children: [
                  Text(
                      representative
                          ? 'اختيار المندوب • موظف المبيعات'
                          : 'اختيار الزبون / الطرف',
                      style: const TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintStyle: TextStyle(color: Colors.black54),
                        hintText: 'ابحث بالاسم',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  ListTile(
                    title: Text(
                        representative
                            ? 'كل موظفي المبيعات'
                            : 'كل الزبائن والأطراف',
                        style: const TextStyle(color: Colors.black87)),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  Expanded(
                      child: ListView.builder(
                    itemCount: people.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text('${people[i]['name']}',
                          style: const TextStyle(color: Colors.black87)),
                      subtitle: representative
                          ? null
                          : Text(
                              people[i]['type'] == 'seller'
                                  ? 'مورد / طرف'
                                  : 'زبون',
                              style: const TextStyle(color: Colors.black54)),
                      onTap: () =>
                          Navigator.pop(context, '${people[i]['key']}'),
                    ),
                  )),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      c.changed(() {
        if (representative) {
          c.representativeId = selected;
        } else {
          c.personKey = selected;
        }
      });
    }
  }

  String _representativeLabel(SalesAccountingController c) {
    if (c.representativeId.isEmpty) return 'المندوب • كل موظفي المبيعات';
    for (final person in c.representatives) {
      if ('${person['key']}' == c.representativeId) {
        return 'المندوب: ${person['name']}';
      }
    }
    return 'مندوب محدد • تغيير';
  }

  Widget _summary(BuildContext context, SalesAccountingController c,
      {Map<String, dynamic>? summaryOverride}) {
    final summary = summaryOverride ?? c.summary;
    final items = <String, String>{
      'عدد الفواتير': '${(summary['invoice_count'] as num?)?.toInt() ?? 0}',
      'المبيعات بعد الخصم':
          SalesAccountingController.amount(summary['sales_total']),
      'خصم المبيعات':
          SalesAccountingController.amount(summary['sales_discount']),
      if (c.returnsVisible) ...{
        'مردودات المبيعات':
            SalesAccountingController.amount(summary['returns_total']),
        'صافي المبيعات': SalesAccountingController.amount(summary['net_sales']),
        'نسبة المرتجعات':
            SalesAccountingController.percentage(summary['return_rate']),
      },
    };
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 800 ? 3 : 2;
      return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.entries
              .map((item) => SizedBox(
                    width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.key,
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 6),
                              FittedBox(
                                  child: Text(item.value,
                                      style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor))),
                            ]),
                      ),
                    ),
                  ))
              .toList());
    });
  }

  Future<void> _export(SalesAccountingController c, String action) async {
    if (c.isLoading || c.isExporting || c.report == null) return;
    c.changed(() => c.isExporting = true);
    try {
      await SalesAccountingExport.export(c, action);
    } catch (_) {
      AppFailureNotice.show(
          title: 'تعذر التصدير', message: 'تعذر تجهيز التقرير. حاول مرة أخرى.');
    } finally {
      c.changed(() => c.isExporting = false);
    }
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.controller, required this.section});
  final SalesAccountingController controller;
  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final rows = controller.rowsFor(section);
    final columns = controller.columns;
    final columnIds = controller.columnIds;
    final widths = controller.columnWidths;
    final theme = Theme.of(context);
    Widget line(List<String> cells,
            {bool header = false,
            bool total = false,
            bool alternate = false}) =>
        Container(
          color: header
              ? AppColors.primaryColor
              : total
                  ? const Color(0xFFE5E7EB)
                  : alternate
                      ? theme.colorScheme.surfaceContainerLow
                      : theme.colorScheme.surface,
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            for (var i = 0; i < cells.length; i++)
              SizedBox(
                width: widths[i],
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Directionality(
                    textDirection: columnIds[i] == 'label' || header
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: Text(cells[i],
                        maxLines: header ? null : 2,
                        overflow: header ? null : TextOverflow.ellipsis,
                        textAlign: columnIds[i] == 'label'
                            ? TextAlign.start
                            : TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: header
                                ? Colors.white
                                : total
                                    ? const Color(0xFF111827)
                                    : null,
                            fontWeight: header || total
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                ),
              ),
          ]),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widths.fold<double>(0, (sum, width) => sum + width),
          child: Column(children: [
            line(columns, header: true),
            SizedBox(
              height: rows.length < 7 ? rows.length * 56.0 : 392,
              child: ListView.builder(
                itemExtent: 56,
                itemCount: rows.length,
                itemBuilder: (_, i) => line(
                    controller.cells(rows[i], sequence: i + 1),
                    alternate: i.isOdd),
              ),
            ),
            line(controller.cells(controller.summaryFor(section), total: true),
                total: true),
          ]),
        ),
      ),
    );
  }
}
