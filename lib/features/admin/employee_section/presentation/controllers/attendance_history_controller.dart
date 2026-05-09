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

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (employeeId.isEmpty) return;
    try {
      isLoading.value = true;
      result.value = await getHistory.call(employeeId: employeeId);
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

  static String formatMinutes(int m) {
    if (m <= 0) return '0 ${'minutesShort'.tr}';
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '$min ${'minutesShort'.tr}';
    return '$h ${'hoursShort'.tr} $min ${'minutesShort'.tr}';
  }
}
