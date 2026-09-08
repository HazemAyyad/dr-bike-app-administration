import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_points_log_model.dart';
import '../../domain/usecases/employee_points_usecases.dart';
import '../../../../../core/helpers/app_success_notice.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
/// Controller for the global "نقاط الموظفين" admin screen that shows every
/// employee with their current month points + reward status, and allows
/// inline add/deduct mutations without entering employee details.
class GlobalEmployeePointsController extends GetxController {
  GlobalEmployeePointsController({
    required this.fetchGlobalUsecase,
    required this.fetchCategoriesUsecase,
    required this.mutateUsecase,
    required this.summaryUsecase,
  });

  final GetGlobalEmployeesPointsUsecase fetchGlobalUsecase;
  final GetEmployeePointCategoriesUsecase fetchCategoriesUsecase;
  final MutateEmployeePointsUsecase mutateUsecase;
  final GetEmployeePointsMonthlySummaryUsecase summaryUsecase;

  // Period filters – default to current month.
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxString searchQuery = ''.obs;

  final RxList<EmployeePointsRowModel> rows = <EmployeePointsRowModel>[].obs;
  final RxList<EmployeePointCategoryModel> categories =
      <EmployeePointCategoryModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isMutating = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadCategories(), loadRows()]);
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

  Future<void> loadRows() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      rows.assignAll(
        await fetchGlobalUsecase.call(
          month: selectedMonth.value,
          year: selectedYear.value,
          search: searchQuery.value,
        ),
      );
    } on Failure catch (e) {
      errorMessage.value = e.errMessage;
      AppFailureNotice.show(
        title: 'error'.tr,
        message: e.errMessage,
      );
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void setSearch(String value) {
    searchQuery.value = value.trim();
    loadRows();
  }

  void updatePeriod({int? month, int? year}) {
    if (month != null) selectedMonth.value = month;
    if (year != null) selectedYear.value = year;
    loadRows();
  }

  Future<bool> mutatePoints({
    required int employeeId,
    required bool isAdd,
    int? points,
    String? category,
    int? categoryId,
    String? reason,
    String? notes,
    DateTime? pointsDate,
    String? imagePath,
  }) async {
    isMutating.value = true;
    try {
      String? formattedDate;
      if (pointsDate != null) {
        formattedDate =
            '${pointsDate.year.toString().padLeft(4, '0')}-${pointsDate.month.toString().padLeft(2, '0')}-${pointsDate.day.toString().padLeft(2, '0')}';
      }
      final result = await mutateUsecase.call(
        employeeId: employeeId,
        isAdd: isAdd,
        points: points,
        category: category,
        categoryId: categoryId,
        reason: reason,
        notes: notes,
        pointsDate: formattedDate,
        imagePath: imagePath,
      );
      return result.fold(
        (failure) {
          AppFailureNotice.show(
            title: 'error'.tr,
            message: failure.errMessage,
          );
          return false;
        },
        (_) async {
          await loadRows();
          AppSuccessNotice.show(
            title: 'success'.tr,
            message: 'pointsUpdatedMessage'.tr,
          );
          return true;
        },
      );
    } finally {
      isMutating.value = false;
    }
  }
}
