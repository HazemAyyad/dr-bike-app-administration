import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../utils/salary_receipt_pdf_builder.dart';
import '../utils/financial_report_pdf_builder.dart';

class PayrollController extends GetxController {
  PayrollController(this.api);

  final DioConsumer api;

  final isLoading = false.obs;
  final isPreviewLoading = false.obs;
  final isPaying = false.obs;
  final downloadingReceiptId = RxnInt();
  final isReportLoading = false.obs;
  final employees = <Map<String, dynamic>>[].obs;
  final boxes = <Map<String, dynamic>>[].obs;
  final previewRows = <Map<String, dynamic>>[].obs;
  final periods = <Map<String, dynamic>>[].obs;
  final selectedEmployeeIds = <int>{}.obs;
  final paymentAmounts = <int, TextEditingController>{};
  final selectedBoxId = RxnInt();
  final month = DateFormat('yyyy-MM').format(DateTime.now()).obs;
  final notesController = TextEditingController();
  final employeeSearchController = TextEditingController();
  final historySearchController = TextEditingController();
  final historyStatus = ''.obs;
  final receiptStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      final requestedMonth = args['month']?.toString();
      if (requestedMonth != null &&
          RegExp(r'^\d{4}-\d{2}$').hasMatch(requestedMonth)) {
        month.value = requestedMonth;
      }
    }
    loadInitial();
  }

  @override
  void onClose() {
    for (final controller in paymentAmounts.values) {
      controller.dispose();
    }
    notesController.dispose();
    employeeSearchController.dispose();
    historySearchController.dispose();
    super.onClose();
  }

  Future<void> loadInitial() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        api.get(EndPoints.payrollEmployees),
        api.get(EndPoints.payrollBoxes),
        api.get(EndPoints.payrollPeriods,
            queryParameters: {'month': month.value}),
      ]);
      employees.assignAll(_mapList(results[0].data['employees']));
      boxes.assignAll(_mapList(results[1].data['boxes']));
      _setPeriods(results[2].data);
      if (selectedBoxId.value != null &&
          !boxes.any((box) => _toInt(box['id']) == selectedBoxId.value)) {
        selectedBoxId.value = null;
      }

      final args = Get.arguments;
      final employeeId = args is Map ? _toInt(args['employee_id']) : null;
      if (employeeId != null &&
          employees.any((row) => _toInt(row['id']) == employeeId)) {
        selectedEmployeeIds.add(employeeId);
      }
    } catch (error) {
      _error(error);
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredEmployees {
    final query = employeeSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return employees;
    return employees.where((row) {
      return '${row['name'] ?? ''} ${row['job_title'] ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredPeriods {
    final query = historySearchController.text.trim().toLowerCase();
    if (query.isEmpty) return periods;
    return periods.where((row) {
      final employee = row['employee'];
      final user = employee is Map ? employee['user'] : null;
      return '${user is Map ? user['name'] ?? '' : ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  void toggleEmployee(int id) {
    selectedEmployeeIds.contains(id)
        ? selectedEmployeeIds.remove(id)
        : selectedEmployeeIds.add(id);
    previewRows.clear();
    update();
  }

  void selectAllVisible() {
    final ids =
        filteredEmployees.map((e) => _toInt(e['id'])).whereType<int>().toSet();
    if (ids.isNotEmpty && ids.every(selectedEmployeeIds.contains)) {
      selectedEmployeeIds.removeAll(ids);
    } else {
      selectedEmployeeIds.addAll(ids);
    }
    previewRows.clear();
    update();
  }

  Future<void> selectMonth(BuildContext context) async {
    final current = DateTime.tryParse('${month.value}-01') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12),
      helpText: 'اختر شهر الراتب',
      fieldLabelText: 'شهر الراتب',
    );
    if (picked == null) return;
    month.value = DateFormat('yyyy-MM').format(picked);
    previewRows.clear();
    await loadHistory();
  }

  Future<void> preview() async {
    if (selectedBoxId.value == null) {
      Get.snackbar('صندوق الدفع مطلوب', 'اختر الصندوق الذي سيُخصم منه الراتب');
      return;
    }
    if (selectedEmployeeIds.isEmpty) {
      Get.snackbar('تنبيه', 'اختر موظفاً واحداً على الأقل');
      return;
    }
    isPreviewLoading.value = true;
    try {
      final response = await api.post(EndPoints.payrollPreview, data: {
        'month': month.value,
        'employee_ids': selectedEmployeeIds.toList(),
      });
      _ensureSuccess(response.data);
      final rows = _mapList(response.data['employees']);
      previewRows.assignAll(rows);
      for (final row in rows) {
        final id = _toInt(row['employee_id']);
        if (id == null) continue;
        paymentAmounts.putIfAbsent(id, () => TextEditingController()).text =
            money(row['remaining']);
      }
    } catch (error) {
      _error(error);
    } finally {
      isPreviewLoading.value = false;
    }
  }

  Future<void> pay() async {
    if (previewRows.isEmpty) {
      await preview();
      if (previewRows.isEmpty) return;
    }
    if (selectedBoxId.value == null) {
      Get.snackbar('تنبيه', 'اختر صندوق الدفع');
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final row in previewRows) {
      final id = _toInt(row['employee_id']);
      final amount = double.tryParse(paymentAmounts[id]?.text.trim() ?? '');
      final remaining = _toDouble(row['remaining']);
      final isNewZeroCashSettlement =
          remaining <= 0 && row['period_id'] == null;
      if (remaining <= 0 && !isNewZeroCashSettlement) continue;
      if (isNewZeroCashSettlement) {
        if (id != null) items.add({'employee_id': id, 'amount_paid': 0});
        continue;
      }
      if (id == null || amount == null || amount <= 0) {
        Get.snackbar('تنبيه', 'راجع مبالغ الدفع المحددة');
        return;
      }
      if (amount > remaining) {
        Get.snackbar('تنبيه', 'مبلغ ${row['employee_name']} يتجاوز المتبقي');
        return;
      }
      items.add({'employee_id': id, 'amount_paid': amount});
    }
    if (items.isEmpty) {
      Get.snackbar('لا توجد مبالغ مستحقة', 'الموظفون المحددون مدفوعون بالكامل');
      return;
    }

    isPaying.value = true;
    try {
      final response = await api.post(EndPoints.payrollPay, data: {
        'month': month.value,
        'box_id': selectedBoxId.value,
        'payment_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'notes': notesController.text.trim(),
        'items': items,
      });
      _ensureSuccess(response.data);
      Get.snackbar(
          'تم بنجاح', response.data['message']?.toString() ?? 'تم صرف الرواتب');
      previewRows.clear();
      selectedEmployeeIds.clear();
      selectedBoxId.value = null;
      notesController.clear();
      await loadInitial();
    } catch (error) {
      _error(error);
    } finally {
      isPaying.value = false;
    }
  }

  Future<void> loadHistory() async {
    try {
      final response =
          await api.get(EndPoints.payrollPeriods, queryParameters: {
        'month': month.value,
        if (historyStatus.value.isNotEmpty) 'status': historyStatus.value,
        if (receiptStatus.value.isNotEmpty)
          'receipt_status': receiptStatus.value,
      });
      _ensureSuccess(response.data);
      _setPeriods(response.data);
    } catch (error) {
      _error(error);
    }
  }

  Future<void> downloadReceipt(int itemId) async {
    if (downloadingReceiptId.value != null) return;
    downloadingReceiptId.value = itemId;
    try {
      final response = await api.get(EndPoints.payrollReceipt(itemId));
      _ensureSuccess(response.data);
      final raw = response.data['receipt'];
      if (raw is! Map) throw Exception('تعذر قراءة بيانات سند الراتب');
      final receipt = Map<String, dynamic>.from(raw);
      Uint8List? signature;
      final path = '${receipt['employee_signature_path'] ?? ''}'.trim();
      if (path.isNotEmpty) {
        try {
          final relative =
              path.startsWith('public/') ? path.substring(7) : path;
          final data = await NetworkAssetBundle(
            Uri.parse('${EndPoints.baserUrlForImage}$relative'),
          ).load('');
          signature = data.buffer.asUint8List();
        } catch (_) {}
      }

      final bytes = await SalaryReceiptPdfBuilder.build(
        receipt: receipt,
        employeeSignature: signature,
      );
      final root = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download/Doctor Bike/Payroll')
          : Directory(
              '${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/Payroll',
            );
      if (!await root.exists()) await root.create(recursive: true);
      final file = File('${root.path}/salary-receipt-$itemId.pdf');
      await file.writeAsBytes(bytes, flush: true);
      Get.snackbar('تم تجهيز السند', 'تم حفظ سند الراتب: ${file.path}');
      await OpenFilex.open(file.path);
    } catch (error) {
      _error(error);
    } finally {
      downloadingReceiptId.value = null;
    }
  }

  Future<void> downloadPayrollReport() async {
    if (isReportLoading.value) return;
    isReportLoading.value = true;
    Get.dialog<void>(
      PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(
                'جاري تجهيز تقرير رواتب ${month.value}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text('سيختفي هذا المؤشر تلقائياً عند اكتمال التقرير'),
            ]),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    try {
      final response = await api.get(
        EndPoints.payrollReport,
        queryParameters: {
          'month': month.value,
          if (historyStatus.value.isNotEmpty) 'status': historyStatus.value,
          if (receiptStatus.value.isNotEmpty)
            'receipt_status': receiptStatus.value,
        },
      );
      _ensureSuccess(response.data);
      final payload = Map<String, dynamic>.from(response.data as Map);
      final bytes = await FinancialReportPdfBuilder.buildPayroll(
        payload: payload,
      );
      final root = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download/Doctor Bike/Reports')
          : Directory(
              '${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/Reports',
            );
      if (!await root.exists()) await root.create(recursive: true);
      final file = File('${root.path}/payroll-report-${month.value}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('تم تجهيز التقرير', 'تم حفظ تقرير الرواتب على جهازك');
      await OpenFilex.open(file.path);
    } catch (error) {
      if (Get.isDialogOpen ?? false) Get.back();
      _error(error);
    } finally {
      isReportLoading.value = false;
      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

  void _setPeriods(dynamic payload) {
    final container = payload is Map ? payload['periods'] : null;
    periods
        .assignAll(_mapList(container is Map ? container['data'] : container));
  }

  void _ensureSuccess(dynamic payload) {
    if (payload is Map && payload['status'] != 'success') {
      final errors = payload['errors'];
      final first =
          errors is Map && errors.isNotEmpty ? errors.values.first : null;
      final detail = first is List && first.isNotEmpty ? first.first : first;
      throw Exception(detail ?? payload['message'] ?? 'تعذر إتمام العملية');
    }
  }

  void _error(Object error) {
    Get.snackbar(
        'تعذر إتمام العملية', error.toString().replaceFirst('Exception: ', ''));
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];

  static int? _toInt(dynamic value) => int.tryParse('$value');
  static double _toDouble(dynamic value) => double.tryParse('$value') ?? 0;
  static String money(dynamic value) => _toDouble(value).toStringAsFixed(2);
}
