import 'package:get/get.dart';
import '../../data/sales_accounting_api_service.dart';

class SalesAccountingController extends GetxController {
  SalesAccountingController({
    required this.service,
    this.savedFilters,
    this.persistFilters,
  });

  final SalesAccountingApiService service;
  final Map<String, dynamic>? savedFilters;
  final Future<void> Function(Map<String, dynamic>?)? persistFilters;
  static const groups = {
    'customer': 'حسب الزبون',
    'month': 'شهري',
    'day': 'يومي'
  };
  static const sorts = {
    'sales_desc': 'الأعلى مبيعًا',
    'sales_asc': 'الأقل مبيعًا',
    'label': 'الاسم / التاريخ',
  };
  late DateTime fromDate;
  late DateTime toDate;
  String groupBy = 'customer';
  String personKey = '';
  String representativeId = '';
  String sort = 'sales_desc';
  String currency = 'شيكل';
  String minAmount = '';
  String maxAmount = '';
  bool includeReturns = false;
  bool cashOnly = false;
  bool includeOtherCurrencies = false;
  bool remember = false;
  bool isLoading = false;
  bool isExporting = false;
  String? error;
  Map<String, dynamic>? report;
  static const _allColumnIds = {
    'sequence',
    'label',
    'gross_sales',
    'sales_discount',
    'sales_total',
    'returns_total',
    'net_sales',
    'sales_share',
    'return_rate',
  };
  Set<String> _selectedColumnIds = {..._allColumnIds};
  Set<String> _appliedColumnIds = {..._allColumnIds};

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = DateTime(now.year, now.month, now.day);
    final saved = savedFilters;
    if (saved != null) {
      final from = DateTime.tryParse('${saved['from_date']}');
      final to = DateTime.tryParse('${saved['to_date']}');
      if (from != null && to != null && !to.isBefore(from)) {
        fromDate = from;
        toDate = to;
      }
      if (groups.containsKey(saved['group_by'])) groupBy = saved['group_by'];
      if (sorts.containsKey(saved['sort'])) sort = saved['sort'];
      personKey = saved['person_key']?.toString() ?? '';
      representativeId = '${saved['representative_id'] ?? ''}';
      includeReturns = saved['include_returns'] == 1;
      cashOnly = saved['cash_only'] == 1 || saved['cash_only'] == true;
      includeOtherCurrencies = saved['include_other_currencies'] == 1 ||
          saved['include_other_currencies'] == true;
      if (currencies.containsKey(saved['currency'])) {
        currency = saved['currency'];
      }
      minAmount = '${saved['min_amount'] ?? ''}';
      maxAmount = '${saved['max_amount'] ?? ''}';
      if (saved['columns'] is List) {
        final restored = (saved['columns'] as List)
            .whereType<String>()
            .where(_allColumnIds.contains)
            .toSet();
        if (restored.isNotEmpty) _selectedColumnIds = restored;
      }
      _ensureVisibleColumn();
      remember = true;
    }
    load();
  }

  static String date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> get filters => {
        'from_date': date(fromDate),
        'to_date': date(toDate),
        'group_by': groupBy,
        'include_returns': includeReturns ? 1 : 0,
        'person_key': personKey,
        'sort': sort,
        'currency': currency,
        'cash_only': cashOnly ? 1 : 0,
        'include_other_currencies': includeOtherCurrencies ? 1 : 0,
        'representative_id': representativeId,
        'min_amount': parseAmount(minAmount),
        'max_amount': parseAmount(maxAmount),
      };

  static const currencies = {
    'شيكل': 'شيكل',
    'دولار': 'دولار',
    'دينار': 'دينار'
  };
  static double? parseAmount(String value) {
    var normalized = value.trim().replaceAll('٫', '.').replaceAll('٬', '');
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    for (var i = 0; i < 10; i++) {
      normalized =
          normalized.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
    }
    return double.tryParse(normalized);
  }

  void selectGroup(String value) => changed(() {
        groupBy = value;
        sort = value == 'customer' ? 'sales_desc' : 'label';
        _ensureVisibleColumn();
      });

  Map<String, String> _columnLabels(String group, bool returns) => {
        if (group == 'month') 'sequence': 'م',
        'label': group == 'month'
            ? 'الشهر / السنة'
            : group == 'customer'
                ? 'الزبون / الطرف'
                : 'التاريخ',
        'gross_sales': group == 'month' ? 'المبيعات' : 'المبيعات قبل الخصم',
        'sales_discount': 'خصم المبيعات',
        if (group != 'month') 'sales_total': 'المبيعات بعد الخصم',
        if (returns) 'returns_total': 'المرتجعات',
        if (group == 'month' || returns) 'net_sales': 'صافي المبيعات',
        'sales_share': 'حصة المبيعات %',
        if (returns) 'return_rate': 'نسبة المرتجعات %',
      };

  Map<String, String> get availableColumns =>
      _columnLabels(groupBy, includeReturns);
  bool isColumnSelected(String id) => _selectedColumnIds.contains(id);
  int get selectedColumnCount =>
      availableColumns.keys.where(isColumnSelected).length;
  void _ensureVisibleColumn() {
    if (selectedColumnCount == 0) _selectedColumnIds.add('label');
  }

  void selectColumn(String id, bool selected) {
    if (!availableColumns.containsKey(id) ||
        (!selected && isColumnSelected(id) && selectedColumnCount == 1)) {
      return;
    }
    changed(() =>
        selected ? _selectedColumnIds.add(id) : _selectedColumnIds.remove(id));
  }

  void selectAllColumns() =>
      changed(() => _selectedColumnIds = {..._allColumnIds});
  void selectReturns(bool value) => changed(() {
        includeReturns = value;
        _ensureVisibleColumn();
      });

  Map<String, dynamic> get _preferences => {
        ...filters,
        'columns': _selectedColumnIds.toList(),
      };
  List<String> get columnIds =>
      _columnLabels('${applied['group_by']}', returnsVisible)
          .keys
          .where(_appliedColumnIds.contains)
          .toList();

  Map<String, dynamic> get applied =>
      Map<String, dynamic>.from(report?['filters'] as Map? ?? {});
  bool get returnsVisible => applied['include_returns'] == true;
  bool get hasPendingFilters =>
      report != null &&
      (valueRangeError != null ||
          _selectedColumnIds.length != _appliedColumnIds.length ||
          !_selectedColumnIds.containsAll(_appliedColumnIds) ||
          filters.entries.any((entry) {
            final other = applied[entry.key];
            if (entry.key == 'min_amount' || entry.key == 'max_amount') {
              return entry.value != num.tryParse('${other ?? ''}');
            }
            return entry.key == 'include_returns' ||
                    entry.key == 'cash_only' ||
                    entry.key == 'include_other_currencies'
                ? (entry.value == 1) != (other == true)
                : '${entry.value ?? ''}' != '${other ?? ''}';
          }));
  Map<String, dynamic> get summary =>
      Map<String, dynamic>.from(report?['summary'] as Map? ?? {});
  List<Map<String, dynamic>> get rows => _maps(report?['rows']);
  List<Map<String, dynamic>> get people => _maps(report?['people']);
  List<Map<String, dynamic>> get representatives =>
      _maps(report?['representatives']);
  List<Map<String, dynamic>> get currencyReports {
    final sections = _maps(report?['currency_reports']);
    return sections.isNotEmpty
        ? sections
        : [
            {
              'currency': report?['currency'],
              'rows': rows,
              'summary': summary,
            }
          ];
  }

  List<Map<String, dynamic>> rowsFor(Map<String, dynamic> section) =>
      _maps(section['rows']);
  Map<String, dynamic> summaryFor(Map<String, dynamic> section) =>
      Map<String, dynamic>.from(section['summary'] as Map? ?? {});
  String get currencyLabel => applied['include_other_currencies'] == true
      ? 'كل عملة بكشف مستقل'
      : '${report?['currency']}';
  List<String> get notes =>
      (report?['notes'] as List? ?? []).map((e) => e.toString()).toList();
  String get reportTitle => applied['group_by'] == 'month'
      ? 'إجمالي المبيعات حسب الأشهر'
      : applied['group_by'] == 'day'
          ? 'إجمالي المبيعات حسب الأيام'
          : 'إجمالي المبيعات حسب الزبون';
  String get period => '${applied['from_date']} — ${applied['to_date']}';

  List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  Future<void> load() async {
    if (isLoading) return;
    if (toDate.isBefore(fromDate)) {
      error = 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية';
      update();
      return;
    }
    if (valueRangeError != null) {
      error = valueRangeError;
      update();
      return;
    }
    _ensureVisibleColumn();
    final requested = Map<String, dynamic>.from(filters);
    final requestedColumns = {..._selectedColumnIds};
    isLoading = true;
    error = null;
    update();
    try {
      report = await service.load(requested);
      _appliedColumnIds = requestedColumns;
      if (persistFilters != null) {
        await persistFilters!(remember
            ? {...requested, 'columns': requestedColumns.toList()}
            : null);
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      report = null;
    } finally {
      isLoading = false;
      update();
    }
  }

  String? get valueRangeError {
    final min = parseAmount(minAmount);
    final max = parseAmount(maxAmount);
    if ((minAmount.trim().isNotEmpty &&
            (min == null || !min.isFinite || min < 0)) ||
        (maxAmount.trim().isNotEmpty &&
            (max == null || !max.isFinite || max < 0)) ||
        (min != null && max != null && max < min)) {
      return 'أدخل نطاق قيمة صحيحًا؛ إلى قيمة يجب أن تكون أكبر من أو تساوي من قيمة';
    }
    return null;
  }

  void changed(void Function() change) {
    change();
    update();
  }

  Future<void> setRemember(bool value) async {
    remember = value;
    update();
    await persistFilters?.call(value ? _preferences : null);
  }

  static String amount(dynamic value) =>
      value == null ? '—' : (num.tryParse('$value') ?? 0).toStringAsFixed(2);
  static String percentage(dynamic value) =>
      value == null ? '—' : '${amount(value)}%';

  bool get isMonthly => applied['group_by'] == 'month';
  List<double> get columnWidths => [
        for (final id in columnIds)
          id == 'sequence'
              ? 72
              : id == 'label'
                  ? (isMonthly ? 150 : 190)
                  : 124
      ];
  List<String> get columns {
    final labels = _columnLabels('${applied['group_by']}', returnsVisible);
    return columnIds.map((id) => labels[id]!).toList();
  }

  Map<String, String> get activeSummaryCardsForDocument =>
      summaryCards(summary);
  Map<String, String> summaryCards(Map<String, dynamic> summary) => {
        'عدد الفواتير': '${summary['invoice_count'] ?? 0}',
        'المبيعات بعد الخصم': amount(summary['sales_total']),
        'خصم المبيعات': amount(summary['sales_discount']),
        if (returnsVisible) ...{
          'المرتجعات': amount(summary['returns_total']),
          'صافي المبيعات': amount(summary['net_sales']),
          'نسبة المرتجعات': percentage(summary['return_rate']),
        },
      };

  List<String> cells(Map<String, dynamic> row,
          {bool total = false, int? sequence}) =>
      [
        for (final id in columnIds)
          if (id == 'sequence')
            total
                ? (columnIds.contains('label') ? '' : 'الإجمالي')
                : '${sequence ?? rows.indexWhere((r) => r['key'] == row['key']) + 1}'
          else if (id == 'label')
            total ? 'الإجمالي' : '${row['label'] ?? ''}'
          else if (id == 'sales_share' || id == 'return_rate')
            percentage(row[id])
          else
            amount(row[id]),
      ];
}
