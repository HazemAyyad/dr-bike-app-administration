import 'dart:async';

import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../data/datasources/employee_datasource.dart';
import '../../data/models/employee_attendance_history_model.dart';
import '../../domain/usecases/get_employee_attendance_history_usecase.dart';

class AttendanceHistoryController extends GetxController {
  AttendanceHistoryController({
    required this.employeeId,
    required this.employeeName,
    required this.getHistory,
  });

  final String employeeId;
  final String employeeName;
  final GetEmployeeAttendanceHistoryUsecase getHistory;

  final RxBool isLoading = false.obs;
  final RxBool isCheckoutLoading = false.obs;
  final Rxn<EmployeeAttendanceHistoryResult> result = Rxn();

  // السنة والشهر المختاران — الافتراضي الشهر الحالي
  final Rx<int> selectedYear  = DateTime.now().year.obs;
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
        to = DateTime(selectedYear.value, selectedMonth.value + 1, 0, 23, 59, 59);
      }

      result.value = await getHistory.call(
        employeeId: employeeId,
        fromDate: from,
        toDate: to,
      );
    } on Failure catch (e) {
      result.value = null;
      Get.snackbar('error'.tr, e.errMessage, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      result.value = null;
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
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
      final raw = await Get.find<EmployeeDatasource>().updateEmployeeAttendanceDay(
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

  /// تغيير الشهر والسنة وإعادة التحميل (يلغي فلتر المدى المخصص)
  void changeMonth(int year, int month) {
    customFrom.value = null;
    customTo.value = null;
    selectedYear.value  = year;
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
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
}
