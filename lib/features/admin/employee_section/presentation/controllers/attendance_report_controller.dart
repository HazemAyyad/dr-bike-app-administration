import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/attendance_report_model.dart';
import '../../domain/entities/working_times_entity.dart';
import '../../domain/usecases/get_attendance_report_usecase.dart';
import '../../utils/attendance_report_export_helper.dart';
import '../models/attendance_report_navigation_args.dart';
import '../widgets/attendance_report_filter_dialog.dart';
import '../../../../../core/helpers/app_success_notice.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
class AttendanceReportController extends GetxController {
  AttendanceReportController({required this.getReport});

  final GetAttendanceReportUsecase getReport;

  final Rxn<AttendanceReportArgs> args = Rxn();
  final RxList<WorkingTimesEntity> employeesForFilter =
      <WorkingTimesEntity>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool showDetailedView = false.obs;
  final Rxn<AttendanceReportResult> result = Rxn();
  final Rxn<String> errorMessage = Rxn();

  @override
  void onInit() {
    super.onInit();
    final raw = Get.arguments;
    if (raw is AttendanceReportNavigationArgs) {
      args.value = raw.reportFilters;
      employeesForFilter.assignAll(raw.employees);
    } else if (raw is AttendanceReportArgs) {
      args.value = raw;
      employeesForFilter.clear();
    } else {
      args.value = null;
    }

    if (args.value == null) {
      Future.microtask(() {
        AppFailureNotice.show(
          title: 'error'.tr,
          message: 'attendanceReportMissingArgs'.tr,
        );
        Get.back();
      });
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (args.value != null) {
      load();
    }
  }

  void applyFilters(AttendanceReportArgs newArgs) {
    args.value = newArgs;
    load();
  }

  Future<void> openFilterDialog(BuildContext context) async {
    final current = args.value;
    if (current == null) return;
    await showAttendanceReportFilterDialog(
      context,
      employees: employeesForFilter.toList(),
      initialFilters: current,
      onApplyInPlace: applyFilters,
    );
  }

  Future<void> load() async {
    final a = args.value;
    if (a == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      result.value = await getReport.call(a);
    } on Failure catch (e) {
      result.value = null;
      errorMessage.value = e.errMessage;
      AppFailureNotice.show(
        title: 'error'.tr,
        message: e.errMessage,
      );
    } catch (e) {
      result.value = null;
      final msg = e.toString();
      errorMessage.value = msg;
      AppFailureNotice.show(
        title: 'error'.tr,
        message: msg,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportPdfShare() async {
    final r = result.value;
    final a = args.value;
    if (r == null || a == null) return;
    try {
      Get.snackbar(
        'info'.tr,
        'reportExportPreparing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      final bytes = await AttendanceReportExportHelper.buildPdfBytes(
        result: r,
        filters: a,
        simple: !showDetailedView.value,
      );
      final name = AttendanceReportExportHelper.fileBaseName(r, 'pdf');
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (e) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: '${'reportExportFailed'.tr}: $e',
      );
    }
  }

  Future<void> exportPdfSaveAndOpen() async {
    final r = result.value;
    final a = args.value;
    if (r == null || a == null) return;
    try {
      Get.snackbar(
        'info'.tr,
        'reportExportPreparing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      final file = await AttendanceReportExportHelper.savePdfToFile(
        result: r,
        filters: a,
        simple: !showDetailedView.value,
      );
      AppSuccessNotice.show(
        title: 'fileDownloadedSuccessfully'.tr,
        message: file.path,
      );
      await OpenFilex.open(file.path);
    } catch (e) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: '${'reportExportFailed'.tr}: $e',
      );
    }
  }

  Future<void> printPdf() async {
    final r = result.value;
    final a = args.value;
    if (r == null || a == null) return;
    try {
      await Printing.layoutPdf(
        onLayout: (_) => AttendanceReportExportHelper.buildPdfBytes(
          result: r,
          filters: a,
          simple: !showDetailedView.value,
        ),
      );
    } catch (e) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: '${'reportExportFailed'.tr}: $e',
      );
    }
  }

  Future<void> exportExcelCsv() async {
    final r = result.value;
    if (r == null) return;
    try {
      Get.snackbar(
        'info'.tr,
        'reportExportPreparing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      final file = await AttendanceReportExportHelper.saveCsvToFile(
        result: r,
      );
      AppSuccessNotice.show(
        title: 'fileDownloadedSuccessfully'.tr,
        message: file.path,
      );
      await OpenFilex.open(file.path);
    } catch (e) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: '${'reportExportFailed'.tr}: $e',
      );
    }
  }
}
