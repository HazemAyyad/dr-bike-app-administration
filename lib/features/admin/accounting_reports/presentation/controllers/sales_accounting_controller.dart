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
  String sort = 'sales_desc';
  bool includeReturns = false;
  bool remember = false;
  bool isLoading = false;
  bool isExporting = false;
  String? error;
  Map<String, dynamic>? report;

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
      includeReturns = saved['include_returns'] == 1;
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
      };

  Map<String, dynamic> get applied =>
      Map<String, dynamic>.from(report?['filters'] as Map? ?? {});
  bool get returnsVisible => applied['include_returns'] == true;
  bool get hasPendingFilters =>
      report != null &&
      filters.entries.any((entry) {
        final other = applied[entry.key];
        return entry.key == 'include_returns'
            ? (entry.value == 1) != (other == true)
            : '${entry.value}' != '${other ?? ''}';
      });
  Map<String, dynamic> get summary =>
      Map<String, dynamic>.from(report?['summary'] as Map? ?? {});
  List<Map<String, dynamic>> get rows => _maps(report?['rows']);
  List<Map<String, dynamic>> get people => _maps(report?['people']);
  List<String> get notes =>
      (report?['notes'] as List? ?? []).map((e) => e.toString()).toList();
  String get reportTitle =>
      'إجمالي المبيعات • ${groups[applied['group_by']] ?? 'حسب الزبون'}';
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
    final requested = Map<String, dynamic>.from(filters);
    isLoading = true;
    error = null;
    update();
    try {
      report = await service.load(requested);
      if (persistFilters != null) {
        await persistFilters!(remember ? requested : null);
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      report = null;
    } finally {
      isLoading = false;
      update();
    }
  }

  void changed(void Function() change) {
    change();
    update();
  }

  Future<void> setRemember(bool value) async {
    remember = value;
    update();
    await persistFilters?.call(value ? filters : null);
  }

  static String amount(dynamic value) =>
      value == null ? '—' : (num.tryParse('$value') ?? 0).toStringAsFixed(2);
  static String percentage(dynamic value) =>
      value == null ? '—' : '${amount(value)}%';

  List<String> get columns => [
        applied['group_by'] == 'customer' ? 'الزبون / الطرف' : 'التاريخ',
        'المبيعات قبل الخصم',
        'خصم المبيعات',
        'المبيعات بعد الخصم',
        if (returnsVisible) ...['المرتجعات', 'خصم المرتجعات', 'صافي المبيعات'],
        'حصة المبيعات %',
        if (returnsVisible) 'نسبة المرتجعات %',
      ];

  Map<String, String> get activeSummaryCardsForDocument => {
        'عدد الفواتير': '${summary['invoice_count'] ?? 0}',
        'المبيعات بعد الخصم': amount(summary['sales_total']),
        'خصم المبيعات': amount(summary['sales_discount']),
        if (returnsVisible) ...{
          'المرتجعات': amount(summary['returns_total']),
          'صافي المبيعات': amount(summary['net_sales']),
          'نسبة المرتجعات': percentage(summary['return_rate']),
        },
      };

  List<String> cells(Map<String, dynamic> row, {bool total = false}) => [
        total ? 'الإجمالي' : '${row['label'] ?? ''}',
        amount(row['gross_sales']),
        amount(row['sales_discount']),
        amount(row['sales_total']),
        if (returnsVisible) ...[
          amount(row['returns_total']),
          amount(row['return_discount']),
          amount(row['net_sales']),
        ],
        percentage(row['sales_share']),
        if (returnsVisible) percentage(row['return_rate']),
      ];
}
