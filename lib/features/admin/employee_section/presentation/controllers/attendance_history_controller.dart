import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
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
