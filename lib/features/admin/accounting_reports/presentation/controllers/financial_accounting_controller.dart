import 'package:get/get.dart';
import '../../data/financial_accounting_api_service.dart';

class FinancialAccountingController extends GetxController {
  FinancialAccountingController(
      {required this.service,
      required this.type,
      this.savedFilters,
      this.initialFilters,
      this.persistFilters});
  final FinancialAccountingApiService service;
  final String type;
  final Map<String, dynamic>? savedFilters;
  final Map<String, dynamic>? initialFilters;
  final Future<void> Function(Map<String, dynamic>?)? persistFilters;
  late DateTime fromDate;
  late DateTime toDate;
  String currency = 'شيكل';
  String categoryKey = '';
  String boxId = '';
  bool includeOpening = false;
  bool remember = false;
  bool loading = false;
  bool exporting = false;
  String? error;
  Map<String, dynamic>? report;
  static const sectionNames = {
    'revenue': 'الإيرادات',
    'sales_returns': 'مردودات المبيعات',
    'cost': 'تكلفة المبيعات',
    'expense': 'المصاريف',
  };
  bool get isExpenses => type == 'expenses';
  String get title =>
      isExpenses ? 'كشف حركات المصاريف' : 'قائمة الدخل المفصّلة';

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = DateTime(now.year, now.month, now.day);
    final saved = initialFilters ?? savedFilters;
    if (saved != null) {
      final from = DateTime.tryParse('${saved['from_date']}');
      final to = DateTime.tryParse('${saved['to_date']}');
      if (from != null && to != null && !to.isBefore(from)) {
        fromDate = from;
        toDate = to;
      }
      if (['شيكل', 'دولار', 'دينار'].contains(saved['currency'])) {
        currency = saved['currency'];
      }
      if (isExpenses) {
        categoryKey = '${saved['category_key'] ?? ''}';
        boxId = '${saved['box_id'] ?? ''}';
        includeOpening =
            saved['include_opening'] == 1 || saved['include_opening'] == true;
      }
      remember = initialFilters == null;
    }
    load();
  }

  static String date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String amount(dynamic v) =>
      v == null ? '—' : (num.tryParse('$v') ?? 0).toStringAsFixed(2);
  Map<String, dynamic> get filters => {
        'from_date': date(fromDate),
        'to_date': date(toDate),
        'currency': currency,
        if (isExpenses) ...{
          'category_key': categoryKey,
          'box_id': boxId,
          'include_opening': includeOpening ? 1 : 0
        },
      };
  Map<String, dynamic> get applied =>
      Map<String, dynamic>.from(report?['filters'] as Map? ?? {});
  Map<String, dynamic> get summary =>
      Map<String, dynamic>.from(report?['summary'] as Map? ?? {});
  String get period => '${applied['from_date']} — ${applied['to_date']}';
  String get appliedCurrency => '${report?['currency'] ?? currency}';
  List<Map<String, dynamic>> maps(dynamic value) => (value as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
  List<Map<String, dynamic>> get rows => maps(report?['rows']);
  List<Map<String, dynamic>> get categories => maps(report?['categories']);
  List<Map<String, dynamic>> get boxes => maps(report?['boxes']);
  List<String> get notes =>
      (report?['notes'] as List? ?? []).map((e) => '$e').toList();
  bool get openingVisible => isExpenses && applied['include_opening'] == true;
  bool get pending =>
      report != null &&
      filters.entries.any((e) => e.key == 'include_opening'
          ? (e.value == 1) != (applied[e.key] == true)
          : '${e.value}' != '${applied[e.key] ?? ''}');

  void changed(void Function() change) {
    change();
    update();
  }

  Future<void> setRemember(bool value) async {
    remember = value;
    update();
    await persistFilters?.call(value ? filters : null);
  }

  Future<void> load() async {
    if (loading) return;
    if (toDate.isBefore(fromDate)) {
      error = 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية';
      update();
      return;
    }
    final requested = Map<String, dynamic>.from(filters);
    loading = true;
    error = null;
    update();
    try {
      report = await service.load(type, requested);
    } catch (e) {
      report = null;
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (report != null && persistFilters != null) {
      try {
        await persistFilters!(remember ? requested : null);
      } catch (_) {
        error = 'تم تحميل التقرير، لكن تعذر حفظ الخيارات';
      }
    }
    loading = false;
    update();
  }

  Map<String, dynamic> expenseDrilldown(Map<String, dynamic> row) => {
        'from_date': applied['from_date'],
        'to_date': applied['to_date'],
        'currency': appliedCurrency,
        'category_key': row['key'],
        'include_opening': 0,
      };

  List<String> get columns => isExpenses
      ? [
          'التاريخ',
          'السند',
          'المصروف',
          'البيان',
          'الصندوق',
          'مدين',
          'دائن',
          'الرصيد',
          'ملاحظات'
        ]
      : ['التصنيف', 'البند', 'مدين', 'دائن', 'الصافي'];
  List<String> cells(Map<String, dynamic> row) => isExpenses
      ? [
          '${row['date']}',
          '${row['entry_number']}',
          '${row['category_name']}',
          '${row['description'] ?? ''}',
          '${row['box_name'] ?? '—'}',
          amount(row['debit']),
          amount(row['credit']),
          amount(row['balance']),
          '${row['notes'] ?? ''}',
        ]
      : [
          sectionNames[row['section']] ?? '',
          '${row['label']}',
          amount(row['debit']),
          amount(row['credit']),
          amount(row['balance'])
        ];
  List<String> get openingCells => [
        'رصيد مدور',
        '',
        '',
        '',
        '',
        '',
        '',
        amount(summary['opening_balance']),
        'قبل بداية الفترة'
      ];
  List<String> get totalCells => isExpenses
      ? [
          'الإجمالي',
          '',
          '',
          '',
          '',
          amount(summary['debit']),
          amount(summary['credit']),
          amount(summary['closing_balance']),
          ''
        ]
      : [
          'النتيجة',
          'صافي الربح / الخسارة',
          '',
          '',
          amount(summary['net_profit'])
        ];
  Map<String, String> get summaryCards => isExpenses
      ? {
          if (openingVisible)
            'الرصيد المدور': amount(summary['opening_balance']),
          'مصروف الفترة الصافي': amount(summary['period_total']),
          'إجمالي مدين': amount(summary['debit']),
          'إجمالي دائن': amount(summary['credit']),
          'الرصيد الختامي': amount(summary['closing_balance']),
          'عدد الحركات': '${summary['movement_count'] ?? 0}',
        }
      : {
          'صافي الإيرادات': amount(summary['net_revenue']),
          'تكلفة المبيعات': amount(summary['cost']),
          'إجمالي الربح': amount(summary['gross_profit']),
          'المصاريف': amount(summary['expenses']),
          'صافي الربح / الخسارة': amount(summary['net_profit']),
        };
}
