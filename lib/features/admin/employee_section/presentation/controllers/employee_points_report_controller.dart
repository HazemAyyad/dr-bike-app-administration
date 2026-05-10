import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_points_log_model.dart';
import '../../domain/usecases/employee_points_usecases.dart';

/// Controller for the global "تقرير النقاط" screen. Aggregates earned /
/// deducted / net points + reward amounts across all (or selected)
/// employees, with optional embedded logs.
class EmployeePointsReportController extends GetxController {
  EmployeePointsReportController({
    required this.fetchReportUsecase,
    required this.fetchCategoriesUsecase,
  });

  final GetGlobalPointsReportUsecase fetchReportUsecase;
  final GetEmployeePointCategoriesUsecase fetchCategoriesUsecase;

  // Filters
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxList<int> selectedEmployeeIds = <int>[].obs;
  final RxnString selectedOperationType = RxnString();
  final RxnInt selectedCategoryId = RxnInt();
  final RxBool includeLogs = false.obs;
  final RxSet<int> expandedRows = <int>{}.obs;

  final Rxn<EmployeePointsReportModel> report = Rxn();
  final RxList<EmployeePointCategoryModel> categories =
      <EmployeePointCategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    runReport();
  }

  Future<void> loadCategories() async {
    try {
      categories.assignAll(
        await fetchCategoriesUsecase.call(isActive: true),
      );
    } on Failure catch (e) {
      errorMessage.value = e.errMessage;
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> runReport() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      report.value = await fetchReportUsecase.call(
        month: selectedMonth.value,
        year: selectedYear.value,
        employeeIds: selectedEmployeeIds.isEmpty
            ? null
            : selectedEmployeeIds.toList(),
        operationType: selectedOperationType.value,
        categoryId: selectedCategoryId.value,
        includeLogs: includeLogs.value,
      );
    } on Failure catch (e) {
      errorMessage.value = e.errMessage;
      Get.snackbar('error'.tr, e.errMessage,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void updatePeriod({int? month, int? year}) {
    if (month != null) selectedMonth.value = month;
    if (year != null) selectedYear.value = year;
    runReport();
  }

  void setEmployeeIds(List<int> ids) {
    selectedEmployeeIds.assignAll(ids);
    runReport();
  }

  void setOperationType(String? value) {
    selectedOperationType.value =
        (value == null || value.isEmpty) ? null : value;
    runReport();
  }

  void setCategoryId(int? id) {
    selectedCategoryId.value = id;
    runReport();
  }

  void toggleIncludeLogs(bool value) {
    includeLogs.value = value;
    runReport();
  }

  void clearFilters() {
    selectedEmployeeIds.clear();
    selectedOperationType.value = null;
    selectedCategoryId.value = null;
    includeLogs.value = false;
    runReport();
  }

  void toggleExpand(int employeeId) {
    if (expandedRows.contains(employeeId)) {
      expandedRows.remove(employeeId);
    } else {
      expandedRows.add(employeeId);
    }
  }
}
