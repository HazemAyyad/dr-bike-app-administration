import 'dart:async';

import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../data/datasources/employee_datasource.dart';
import '../../data/models/employee_attendance_history_model.dart';
import '../../domain/usecases/get_employee_attendance_history_usecase.dart';
import '../../utils/employee_attendance_history_pdf_helper.dart';

class AttendanceHistoryController extends GetxController {
  AttendanceHistoryController({
    required this.employeeId,
    required this.employeeName,
    required this.getHistory,
    this.reportMode = false,
  });

  final String employeeId;
  final String employeeName;
  final GetEmployeeAttendanceHistoryUsecase getHistory;
  final bool reportMode;

  final RxBool isLoading = false.obs;
  final RxBool isCheckoutLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxBool isWeeklyOffImportLoading = false.obs;
  final RxString importingWeeklyOffDate = ''.obs;
  final Rxn<EmployeeAttendanceHistoryResult> result = Rxn();
  final RxList<WeeklyOffAttendanceImportCandidate> weeklyOffImportCandidates =
      <WeeklyOffAttendanceImportCandidate>[].obs;

  // السنة والشهر المختاران — الافتراضي الشهر الحالي
  final Rx<int> selectedYear = DateTime.now().year.obs;
  final Rx<int> selectedMonth = DateTime.now().month.obs;

  // فلتر مدى الأيام (من / إلى) — يلغي وضع الشهر عند تفعيله
  final Rxn<DateTime> customFrom = Rxn<DateTime>();
  final Rxn<DateTime> customTo = Rxn<DateTime>();

  bool get isCustomRange => customFrom.value != null && customTo.value != null;

  Timer? _liveRefreshTimer;

  String get _todayDateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool get _shouldLiveRefresh {
    if (!includesToday || employeeId.isEmpty) return false;
    final data = result.value;
    if (data == null) return false;
    if (data.employee.currentlyInToday) return true;
    for (final d in data.days) {
      if (d.date == _todayDateKey && d.currentlyIn) return true;
    }
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    load();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_shouldLiveRefresh) {
        load(silent: true);
      }
    });
  }

  @override
  void onClose() {
    _liveRefreshTimer?.cancel();
    super.onClose();
  }

  /// تحميل البيانات بناءً على الشهر والسنة المختارَيْن
  Future<void> load({bool silent = false}) async {
    if (employeeId.isEmpty) return;
    try {
      if (!silent) isLoading.value = true;

      final DateTime from;
      final DateTime to;
      if (isCustomRange) {
        final f = customFrom.value!;
        final t = customTo.value!;
        from = DateTime(f.year, f.month, f.day);
        to = DateTime(t.year, t.month, t.day, 23, 59, 59);
      } else {
        from = DateTime(selectedYear.value, selectedMonth.value, 1);
        // آخر يوم في الشهر
        to = DateTime(
            selectedYear.value, selectedMonth.value + 1, 0, 23, 59, 59);
      }

      result.value = await getHistory.call(
        employeeId: employeeId,
        fromDate: from,
        toDate: to,
        includeEmptyDays: reportMode,
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
      if (!silent) isLoading.value = false;
    }
  }

  bool get isViewingCurrentMonth {
    final now = DateTime.now();
    return selectedYear.value == now.year && selectedMonth.value == now.month;
  }

  /// هل الفترة المعروضة (شهر أو مدى مخصص) تشمل اليوم؟
  bool get includesToday {
    final now = DateTime.now();
    if (isCustomRange) {
      final f = customFrom.value!;
      final t = customTo.value!;
      final start = DateTime(f.year, f.month, f.day);
      final end = DateTime(t.year, t.month, t.day, 23, 59, 59);
      return !now.isBefore(start) && !now.isAfter(end);
    }
    return isViewingCurrentMonth;
  }

  bool get canManualCheckoutToday {
    if (!includesToday || employeeId.isEmpty) return false;
    final data = result.value;
    if (data == null) return false;
    if (data.employee.currentlyInToday) return true;
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    for (final d in data.days) {
      if (d.date == todayKey && d.currentlyIn) return true;
    }
    return false;
  }

  String get periodLabel {
    if (isCustomRange) {
      final f = customFrom.value!;
      final t = customTo.value!;
      return '${_dateKey(f)} - ${_dateKey(t)}';
    }
    return '${selectedYear.value}-${selectedMonth.value.toString().padLeft(2, '0')}';
  }

  String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  _AttendanceHistoryRange get _currentRange {
    if (isCustomRange) {
      final f = customFrom.value!;
      final t = customTo.value!;
      return _AttendanceHistoryRange(
        DateTime(f.year, f.month, f.day),
        DateTime(t.year, t.month, t.day, 23, 59, 59),
      );
    }

    return _AttendanceHistoryRange(
      DateTime(selectedYear.value, selectedMonth.value, 1),
      DateTime(selectedYear.value, selectedMonth.value + 1, 0, 23, 59, 59),
    );
  }

  Future<EmployeeAttendanceHistoryResult?> _ensureReportData() async {
    if (result.value == null) {
      await load();
    }
    return result.value;
  }

  Future<void> exportPdfShare() async {
    if (isExporting.value) return;
    try {
      isExporting.value = true;
      final data = await _ensureReportData();
      if (data == null) return;
      Get.snackbar(
        'info'.tr,
        'reportExportPreparing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      final bytes = await EmployeeAttendanceHistoryPdfHelper.buildPdfBytes(
        result: data,
        periodLabel: periodLabel,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'employee_attendance_${employeeId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        '${'reportExportFailed'.tr}: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportPdfSaveAndOpen() async {
    if (isExporting.value) return;
    try {
      isExporting.value = true;
      final data = await _ensureReportData();
      if (data == null) return;
      Get.snackbar(
        'info'.tr,
        'reportExportPreparing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      final file = await EmployeeAttendanceHistoryPdfHelper.savePdfToFile(
        result: data,
        periodLabel: periodLabel,
      );
      Get.snackbar(
        'fileDownloadedSuccessfully'.tr,
        file.path,
        snackPosition: SnackPosition.BOTTOM,
      );
      await OpenFilex.open(file.path);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        '${'reportExportFailed'.tr}: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<bool> manualCheckout() async {
    if (employeeId.isEmpty || isCheckoutLoading.value) return false;
    try {
      isCheckoutLoading.value = true;
      final raw = await Get.find<EmployeeDatasource>()
          .manualEmployeeCheckout(employeeId: employeeId);
      final status = raw['status']?.toString() ?? '';
      if (status != 'success') {
        Get.snackbar(
          'error'.tr,
          raw['message']?.toString() ?? 'error'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
      Get.snackbar(
        'success'.tr,
        raw['message']?.toString() ?? 'manualCheckoutSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      await load();
      return true;
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isCheckoutLoading.value = false;
    }
  }

  Future<bool> updateAttendanceDay({
    required String workDate,
    required DateTime checkInAt,
    DateTime? checkOutAt,
  }) async {
    if (employeeId.isEmpty) return false;
    try {
      final raw =
          await Get.find<EmployeeDatasource>().updateEmployeeAttendanceDay(
        employeeId: employeeId,
        workDate: workDate,
        checkInAt: checkInAt,
        checkOutAt: checkOutAt,
      );
      if (raw['status']?.toString() != 'success') {
        Get.snackbar(
          'error'.tr,
          raw['message']?.toString() ?? 'error'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
      Get.snackbar(
        'success'.tr,
        raw['message']?.toString() ?? 'settingsUpdated'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      await load();
      return true;
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> loadWeeklyOffImportCandidates() async {
    if (employeeId.isEmpty || isWeeklyOffImportLoading.value) return;
    try {
      isWeeklyOffImportLoading.value = true;
      final range = _currentRange;
      weeklyOffImportCandidates.value = await Get.find<EmployeeDatasource>()
          .getWeeklyOffAttendanceImportCandidates(
        employeeId: employeeId,
        fromDate: range.fromDate,
        toDate: range.toDate,
      );
    } on ServerException catch (e) {
      weeklyOffImportCandidates.clear();
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      weeklyOffImportCandidates.clear();
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isWeeklyOffImportLoading.value = false;
    }
  }

  Future<bool> importWeeklyOffAttendanceDay(String date) async {
    if (employeeId.isEmpty || importingWeeklyOffDate.value.isNotEmpty) {
      return false;
    }
    try {
      importingWeeklyOffDate.value = date;
      final raw =
          await Get.find<EmployeeDatasource>().importWeeklyOffAttendanceDay(
        employeeId: employeeId,
        date: date,
      );
      if (raw['status']?.toString() != 'success') {
        Get.snackbar(
          'error'.tr,
          raw['message']?.toString() ?? 'error'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      Get.snackbar(
        'success'.tr,
        'weeklyOffImportSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      weeklyOffImportCandidates.removeWhere((d) => d.date == date);
      await load(silent: true);
      return true;
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      importingWeeklyOffDate.value = '';
    }
  }

  /// تغيير الشهر والسنة وإعادة التحميل (يلغي فلتر المدى المخصص)
  void changeMonth(int year, int month) {
    customFrom.value = null;
    customTo.value = null;
    selectedYear.value = year;
    selectedMonth.value = month;
    load();
  }

  /// تطبيق فلتر مدى الأيام (من / إلى) وإعادة التحميل
  void applyDateRange(DateTime from, DateTime to) {
    // ضمان أن البداية قبل النهاية
    if (from.isAfter(to)) {
      final tmp = from;
      from = to;
      to = tmp;
    }
    customFrom.value = DateTime(from.year, from.month, from.day);
    customTo.value = DateTime(to.year, to.month, to.day);
    load();
  }

  /// إلغاء فلتر المدى والعودة لعرض الشهر المختار
  void clearDateRange() {
    if (!isCustomRange) return;
    customFrom.value = null;
    customTo.value = null;
    load();
  }

  static String formatMinutes(int m) => formatWorkedDurationMinutes(m);

  /// قائمة السنوات المتاحة (5 سنوات للوراء)
  List<int> get availableYears {
    final now = DateTime.now().year;
    return List.generate(5, (i) => now - i);
  }

  /// أسماء الأشهر بالعربية
  static const List<String> monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
}

class _AttendanceHistoryRange {
  final DateTime fromDate;
  final DateTime toDate;

  const _AttendanceHistoryRange(this.fromDate, this.toDate);
}
