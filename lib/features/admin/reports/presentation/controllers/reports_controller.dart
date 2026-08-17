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

  DateTime? fromDate;
  DateTime? toDate;
  Map<String, dynamic> salesSummary = const {};
  List<Map<String, dynamic>> salesRows = const [];

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
    } catch (e) {
      salesSummary = const {};
      salesRows = const [];
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> openReport(String key) async {
    selectedReport.value = key;
    update();
    if (key == 'sales' && salesRows.isEmpty) {
      await loadSalesReport();
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
      loadSalesReport();
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
    await loadSalesReport();
  }

  String money(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    return number.toStringAsFixed(2);
  }
}
