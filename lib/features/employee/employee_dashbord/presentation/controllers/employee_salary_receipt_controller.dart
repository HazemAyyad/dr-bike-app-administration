import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../admin/financial_affairs/presentation/utils/salary_receipt_pdf_builder.dart';

class EmployeeSalaryReceiptController extends GetxController {
  EmployeeSalaryReceiptController(this.api);

  final DioConsumer api;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final receipts = <Map<String, dynamic>>[].obs;
  final allReceipts = <Map<String, dynamic>>[].obs;
  final historyLoading = false.obs;
  final downloadingReceiptId = RxnInt();
  final historyStatus = ''.obs;
  final historyMonth = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await api.get(EndPoints.employeePendingSalaryReceipts);
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        final list = data['receipts'];
        receipts.assignAll(list is List
            ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
            : const []);
      }
    } catch (_) {
      // The dashboard remains usable if payroll is not deployed yet.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory() async {
    historyLoading.value = true;
    try {
      final response = await api.get(
        EndPoints.employeeSalaryReceipts,
        queryParameters: {
          if (historyStatus.value.isNotEmpty) 'status': historyStatus.value,
          if (historyMonth.value.isNotEmpty) 'month': historyMonth.value,
        },
      );
      _ensureSuccess(response.data);
      final block = response.data['receipts'];
      final list = block is Map ? block['data'] : block;
      allReceipts.assignAll(list is List
          ? list.whereType<Map>().map((row) => Map<String, dynamic>.from(row))
          : const []);
    } catch (error) {
      Get.snackbar(
        'تعذر تحميل سندات الرواتب',
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      historyLoading.value = false;
    }
  }

  Future<void> downloadReceipt(int id) async {
    if (downloadingReceiptId.value != null) return;
    downloadingReceiptId.value = id;
    try {
      final response = await api.get(EndPoints.employeeSalaryReceipt(id));
      _ensureSuccess(response.data);
      final raw = response.data['receipt'];
      if (raw is! Map) throw Exception('تعذر قراءة بيانات السند');
      final receipt = Map<String, dynamic>.from(raw);
      Uint8List? signature;
      final signaturePath = '${receipt['employee_signature_path'] ?? ''}';
      if (signaturePath.isNotEmpty) {
        try {
          final relative = signaturePath.startsWith('public/')
              ? signaturePath.substring(7)
              : signaturePath;
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
      final folder = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download/Doctor Bike/My Salaries')
          : Directory(
              '${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/My Salaries',
            );
      if (!await folder.exists()) await folder.create(recursive: true);
      final file = File('${folder.path}/my-salary-receipt-$id.pdf');
      await file.writeAsBytes(bytes, flush: true);
      Get.snackbar('تم تجهيز السند', 'تم حفظ سند الراتب على جهازك');
      await OpenFilex.open(file.path);
    } catch (error) {
      Get.snackbar(
        'تعذر تنزيل السند',
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      downloadingReceiptId.value = null;
    }
  }

  Future<bool> acknowledge(int id, List<int> pngBytes) async {
    isSubmitting.value = true;
    try {
      final response = await api.post(
        EndPoints.acknowledgeSalaryReceipt(id),
        data: {
          'signature': 'data:image/png;base64,${base64Encode(pngBytes)}',
          'device': GetPlatform.isAndroid
              ? 'Doctor Bike Android App'
              : 'Doctor Bike App',
        },
      );
      _ensureSuccess(response.data);
      receipts.removeWhere((row) => int.tryParse('${row['id']}') == id);
      await loadHistory();
      Get.snackbar('تم توثيق الاستلام', 'تم حفظ توقيعك وإبلاغ الإدارة بنجاح');
      return true;
    } catch (error) {
      Get.snackbar(
          'تعذر حفظ التوقيع', error.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> dispute(int id, String reason) async {
    if (reason.trim().length < 3) {
      Get.snackbar('السبب مطلوب', 'اكتب سبب الاعتراض بوضوح');
      return false;
    }
    isSubmitting.value = true;
    try {
      final response = await api.post(
        EndPoints.disputeSalaryReceipt(id),
        data: {'reason': reason.trim()},
      );
      _ensureSuccess(response.data);
      receipts.removeWhere((row) => int.tryParse('${row['id']}') == id);
      await loadHistory();
      Get.snackbar('تم إرسال الاعتراض', 'سيظهر الاعتراض مباشرة لدى الإدارة');
      return true;
    } catch (error) {
      Get.snackbar('تعذر إرسال الاعتراض',
          error.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _ensureSuccess(dynamic data) {
    if (data is Map && data['status'] != 'success') {
      final errors = data['errors'];
      final first =
          errors is Map && errors.isNotEmpty ? errors.values.first : null;
      throw Exception(first is List && first.isNotEmpty
          ? first.first
          : data['message'] ?? 'تعذر إتمام العملية');
    }
  }

  static String money(dynamic value) =>
      (double.tryParse('$value') ?? 0).toStringAsFixed(2);
}
