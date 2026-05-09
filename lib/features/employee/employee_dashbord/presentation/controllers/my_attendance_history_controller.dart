import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../admin/employee_section/data/models/employee_attendance_history_model.dart';
import '../../../../admin/employee_section/presentation/controllers/attendance_history_controller.dart';
import '../../domain/usecases/get_my_attendance_history_usecase.dart';

class MyAttendanceHistoryController extends GetxController {
  MyAttendanceHistoryController({required this.getMyAttendanceHistoryUsecase});

  final GetMyAttendanceHistoryUsecase getMyAttendanceHistoryUsecase;

  final RxBool isLoading = false.obs;
  final Rxn<EmployeeAttendanceHistoryResult> result = Rxn();

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      result.value = await getMyAttendanceHistoryUsecase.call(
        fromDate: fromDate,
        toDate: toDate,
      );
    } on Failure catch (e) {
      result.value = null;
      Get.snackbar('error'.tr, e.errMessage,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      result.value = null;
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
    );
    if (picked != null) {
      fromDate = picked.start;
      toDate = picked.end;
      await load();
    }
  }

  static String formatRange(DateTime a, DateTime b) {
    final f = DateFormat('yyyy-MM-dd');
    return '${f.format(a)} — ${f.format(b)}';
  }

  static String formatMinutes(int m) =>
      AttendanceHistoryController.formatMinutes(m);
}
