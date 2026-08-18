import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/reports_api_service.dart';

class ReportsController extends GetxController {
  ReportsController({required this.service});

  final ReportsApiService service;

  final RxBool isLoading = false.obs;
  final RxString selectedReport = ''.obs;
  final RxString selectedPeriod = 'month'.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedPaymentType = 'all'.obs;
  final RxString selectedCheckDirection = 'all'.obs;

  DateTime? fromDate;
  DateTime? toDate;
  Map<String, dynamic> salesSummary = const {};
  List<Map<String, dynamic>> salesRows = const [];
  List<Map<String, dynamic>> reportSummary = const [];
  List<String> reportColumns = const [];
  List<Map<String, dynamic>> reportRows = const [];
  Map<String, dynamic> reportPeriod = const {};

  final reports = const [
    {'key': 'sales', 'title': 'تقرير المبيعات'},
    {'key': 'balances', 'title': 'أرصدة الزبائن والموردين'},
    {'key': 'statement', 'title': 'كشف حساب شخص'},
    {'key': 'checks', 'title': 'الشيكات الصادرة والواردة'},
    {'key': 'boxes', 'title': 'كشف حساب الصناديق'},
    {'key': 'inventory', 'title': 'كميات وقيمة المخزون'},
    {'key': 'income', 'title': 'قائمة الدخل'},
    {'key': 'sales_returns', 'title': 'مردودات المبيعات'},
    {'key': 'product_profit', 'title': 'نسبة ربح المنتجات'},
  ];

  final periods = const [
    {'key': 'today', 'title': 'يومي'},
    {'key': 'week', 'title': 'أسبوعي'},
    {'key': 'month', 'title': 'شهري'},
    {'key': 'quarter', 'title': '3 شهور'},
    {'key': 'half_year', 'title': 'نصف سنة'},
    {'key': 'year', 'title': 'سنوي'},
    {'key': 'custom', 'title': 'فترة مخصصة'},
  ];

  final statuses = const [
    {'key': 'all', 'title': 'الكل'},
    {'key': 'active', 'title': 'فعال'},
    {'key': 'cancelled', 'title': 'ملغي'},
  ];

  final paymentTypes = const [
    {'key': 'all', 'title': 'كل طرق الدفع'},
    {'key': 'cash', 'title': 'نقدي'},
    {'key': 'debt', 'title': 'على الدين'},
    {'key': 'mixed', 'title': 'مختلط'},
  ];

  final checkDirections = const [
    {'key': 'all', 'title': 'الصادرة والواردة'},
    {'key': 'incoming', 'title': 'الواردة فقط'},
    {'key': 'outgoing', 'title': 'الصادرة فقط'},
  ];

  Future<void> loadSalesReport() async {
    isLoading(true);
    update();
    try {
      final data = await service.salesReport(
        period: selectedPeriod.value,
        fromDate: selectedPeriod.value == 'custom' ? fromDate : null,
        toDate: selectedPeriod.value == 'custom' ? toDate : null,
        status: selectedStatus.value,
        paymentType: selectedPaymentType.value,
      );
      salesSummary = Map<String, dynamic>.from(data['summary'] ?? {});
      salesRows = (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      reportPeriod = Map<String, dynamic>.from(data['period'] ?? {});
    } catch (e) {
      salesSummary = const {};
      salesRows = const [];
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> loadGenericReport() async {
    final type = selectedReport.value;
    if (type.isEmpty || type == 'sales') return;

    isLoading(true);
    update();
    try {
      final data = await service.reportData(
        type: type,
        period: selectedPeriod.value,
        fromDate: selectedPeriod.value == 'custom' ? fromDate : null,
        toDate: selectedPeriod.value == 'custom' ? toDate : null,
        checkDirection: selectedCheckDirection.value,
      );
      reportSummary = (data['summary'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      reportColumns = (data['columns'] as List? ?? const [])
          .map((column) => column.toString())
          .toList(growable: false);
      reportRows = (data['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      reportPeriod = Map<String, dynamic>.from(data['period'] ?? {});
    } catch (e) {
      reportSummary = const [];
      reportColumns = const [];
      reportRows = const [];
      reportPeriod = const {};
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> loadCurrentReport() {
    return selectedReport.value == 'sales'
        ? loadSalesReport()
        : loadGenericReport();
  }

  Future<void> openReport(String key) async {
    selectedReport.value = key;
    update();
    if (key == 'sales') {
      await loadSalesReport();
    } else {
      await loadGenericReport();
    }
  }

  void selectReport(String key) {
    selectedReport.value = key;
    update();
  }

  void selectPeriod(String key) {
    selectedPeriod.value = key;
    if (key != 'custom') {
      fromDate = null;
      toDate = null;
      loadCurrentReport();
    } else {
      update();
    }
  }

  void selectStatus(String key) {
    selectedStatus.value = key;
    loadSalesReport();
  }

  void selectPaymentType(String key) {
    selectedPaymentType.value = key;
    loadSalesReport();
  }

  void selectCheckDirection(String key) {
    selectedCheckDirection.value = key;
    loadGenericReport();
  }

  Future<void> pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: fromDate ?? DateTime(now.year, now.month, 1),
        end: toDate ?? now,
      ),
    );
    if (picked == null) return;
    fromDate = picked.start;
    toDate = picked.end;
    selectedPeriod.value = 'custom';
    await loadCurrentReport();
  }

  String money(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    return number.toStringAsFixed(2);
  }

  List<String> activeColumns() {
    if (selectedReport.value == 'sales') {
      return const [
        'الرقم',
        'التاريخ',
        'الزبون',
        'الصنف',
        'الكمية',
        'الإجمالي',
        'المدفوع',
        'المتبقي',
        'الدفع',
        'الحالة',
      ];
    }
    return reportColumns;
  }

  List<Map<String, dynamic>> activeSummaryCards() {
    if (selectedReport.value != 'sales') return reportSummary;
    return [
      {'title': 'عدد الفواتير', 'value': salesSummary['invoice_count']},
      {
        'title': 'الفواتير الفعالة',
        'value': salesSummary['active_invoice_count']
      },
      {'title': 'المبيعات', 'value': money(salesSummary['gross_sales'])},
      {'title': 'النقدي', 'value': money(salesSummary['cash_paid'])},
      {'title': 'على الدين', 'value': money(salesSummary['debt_remaining'])},
      {'title': 'الخصومات', 'value': money(salesSummary['discounts'])},
      {'title': 'الملغي', 'value': money(salesSummary['cancelled_sales'])},
    ];
  }

  List<Map<String, dynamic>> activeRows() {
    return selectedReport.value == 'sales' ? salesRows : reportRows;
  }

  List<String> cellsForRow(Map<String, dynamic> row) {
    switch (selectedReport.value) {
      case 'sales':
        return [
          '${row['serial_number'] ?? row['id'] ?? ''}',
          '${row['date'] ?? ''}',
          '${row['buyer_name'] ?? ''}',
          '${row['product_name'] ?? ''}',
          '${row['quantity'] ?? ''}',
          money(row['total']),
          money(row['paid']),
          money(row['remaining']),
          paymentLabel(row['payment_type']),
          row['status'] == 'cancelled' ? 'ملغي' : 'فعال',
        ];
      case 'balances':
        return [
          '${row['type'] ?? ''}',
          '${row['name'] ?? ''}',
          '${row['phone'] ?? ''}',
          money(row['balance_abs']),
          '${row['status'] ?? ''}',
        ];
      case 'statement':
        return [
          '${row['date'] ?? ''}',
          '${row['person'] ?? ''}',
          '${row['person_type'] ?? ''}',
          money(row['amount']),
          '${row['currency'] ?? ''}',
          money(row['balance_after']),
          '${row['box'] ?? ''}',
          '${row['note'] ?? ''}',
        ];
      case 'checks':
        return [
          '${row['direction'] ?? ''}',
          '${row['check_id'] ?? ''}',
          '${row['bank_name'] ?? ''}',
          '${row['person'] ?? ''}',
          money(row['total']),
          '${row['currency'] ?? ''}',
          '${row['due_date'] ?? ''}',
          '${row['status'] ?? ''}',
        ];
      case 'boxes':
        return [
          '${row['date'] ?? ''}',
          '${row['box'] ?? ''}',
          '${row['from_box'] ?? ''}',
          '${row['to_box'] ?? ''}',
          '${row['type'] ?? ''}',
          money(row['amount']),
          '${row['description'] ?? ''}',
        ];
      case 'inventory':
        return [
          '${row['code'] ?? ''}',
          '${row['product'] ?? ''}',
          money(row['quantity']),
          money(row['unit_cost']),
          money(row['total_cost']),
          money(row['opening_value']),
          money(row['ending_value']),
        ];
      case 'income':
        return [
          '${row['account'] ?? ''}',
          money(row['debit']),
          money(row['credit']),
        ];
      case 'sales_returns':
        return [
          '${row['serial'] ?? ''}',
          '${row['date'] ?? ''}',
          '${row['buyer'] ?? ''}',
          '${row['product'] ?? ''}',
          '${row['quantity'] ?? ''}',
          money(row['total']),
          '${row['cancelled_at'] ?? ''}',
        ];
      case 'product_profit':
        return [
          '${row['code'] ?? ''}',
          '${row['product'] ?? ''}',
          money(row['quantity']),
          money(row['sales_total']),
          money(row['cost_total']),
          money(row['profit']),
          '${row['profit_percent'] ?? ''}',
        ];
      default:
        return row.values.map((value) => value?.toString() ?? '').toList();
    }
  }

  String paymentLabel(dynamic value) {
    switch (value?.toString()) {
      case 'cash':
        return 'نقدي';
      case 'debt':
        return 'على الدين';
      case 'mixed':
        return 'مختلط';
      default:
        return 'غير محدد';
    }
  }
}
