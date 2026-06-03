import 'package:get/get.dart';

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

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// تحميل البيانات بناءً على الشهر والسنة المختارَيْن
  Future<void> load() async {
    if (employeeId.isEmpty) return;
    try {
      isLoading.value = true;

      final from = DateTime(selectedYear.value, selectedMonth.value, 1);
      // آخر يوم في الشهر
      final to   = DateTime(selectedYear.value, selectedMonth.value + 1, 0, 23, 59, 59);

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
      isLoading.value = false;
    }
  }

  bool get isViewingCurrentMonth {
    final now = DateTime.now();
    return selectedYear.value == now.year && selectedMonth.value == now.month;
  }

  bool get canManualCheckoutToday {
    if (!isViewingCurrentMonth || employeeId.isEmpty) return false;
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

  /// تغيير الشهر والسنة وإعادة التحميل
  void changeMonth(int year, int month) {
    selectedYear.value  = year;
    selectedMonth.value = month;
    load();
  }

  static String formatMinutes(int m) {
    if (m <= 0) return '0 ${'minutesShort'.tr}';
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '$min ${'minutesShort'.tr}';
    return '$h ${'hoursShort'.tr} $min ${'minutesShort'.tr}';
  }

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
