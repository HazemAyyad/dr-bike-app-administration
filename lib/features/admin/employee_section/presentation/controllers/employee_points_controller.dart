import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_points_log_model.dart';
import '../../domain/usecases/employee_points_usecases.dart';

/// Controller backing the "Points & Rewards" tab inside an employee
/// details screen. Keeps current month summary, paginated logs, filters,
/// categories list and exposes mutation calls for the UI.
class EmployeePointsController extends GetxController {
  EmployeePointsController({
    required this.mutateUsecase,
    required this.logsUsecase,
    required this.summaryUsecase,
    required this.categoriesUsecase,
  });

  final MutateEmployeePointsUsecase mutateUsecase;
  final GetEmployeePointsLogsUsecase logsUsecase;
  final GetEmployeePointsMonthlySummaryUsecase summaryUsecase;
  final GetEmployeePointsCategoriesUsecase categoriesUsecase;

  final RxInt currentEmployeeId = 0.obs;

  // Period filters – default to "current month".
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxnString selectedCategory = RxnString();
  final RxnString selectedOperationType = RxnString();

  final Rxn<EmployeePointsMonthlySummaryModel> summary = Rxn();
  final RxList<EmployeePointsLogModel> logs = <EmployeePointsLogModel>[].obs;
  final Rxn<EmployeePointsCategoriesModel> categories = Rxn();

  final RxBool isSummaryLoading = false.obs;
  final RxBool isLogsLoading = false.obs;
  final RxBool isCategoriesLoading = false.obs;
  final RxBool isMutating = false.obs;
  final RxnString errorMessage = RxnString();

  bool get hasEmployee => currentEmployeeId.value > 0;

  /// Sets the active employee id and reloads everything.
  Future<void> bindEmployee(int employeeId) async {
    currentEmployeeId.value = employeeId;
    if (categories.value == null) {
      await loadCategories();
    }
    await Future.wait([
      loadMonthlySummary(),
      loadLogs(reset: true),
    ]);
  }

  Future<void> loadCategories() async {
    try {
      isCategoriesLoading.value = true;
      categories.value = await categoriesUsecase.call();
    } on Failure catch (e) {
      errorMessage.value = e.errMessage;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> loadMonthlySummary() async {
    if (!hasEmployee) return;
    try {
      isSummaryLoading.value = true;
      errorMessage.value = null;
      summary.value = await summaryUsecase.call(
        employeeId: currentEmployeeId.value,
        month: selectedMonth.value,
        year: selectedYear.value,
      );
    } on Failure catch (e) {
      errorMessage.value = e.errMessage;
      Get.snackbar('error'.tr, e.errMessage,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isSummaryLoading.value = false;
    }
  }

  Future<void> loadLogs({bool reset = false}) async {
    if (!hasEmployee) return;
    try {
      isLogsLoading.value = true;
      if (reset) {
        logs.clear();
      }
      final page = await logsUsecase.call(
        employeeId: currentEmployeeId.value,
        month: selectedMonth.value,
        year: selectedYear.value,
        category: selectedCategory.value,
        operationType: selectedOperationType.value,
      );
      logs.assignAll(page.items);
    } on Failure catch (e) {
      errorMessage.value = e.errMessage;
      Get.snackbar('error'.tr, e.errMessage,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLogsLoading.value = false;
    }
  }

  void updatePeriod({int? month, int? year}) {
    if (month != null) selectedMonth.value = month;
    if (year != null) selectedYear.value = year;
    loadMonthlySummary();
    loadLogs(reset: true);
  }

  void updateFilters({String? category, String? operationType}) {
    selectedCategory.value = (category != null && category.isEmpty) ? null : category;
    selectedOperationType.value =
        (operationType != null && operationType.isEmpty) ? null : operationType;
    loadLogs(reset: true);
  }

  void clearFilters() {
    selectedCategory.value = null;
    selectedOperationType.value = null;
    loadLogs(reset: true);
  }

  /// Returns true when the points were saved successfully.
  ///
  /// When [categoryId] is provided the backend resolves operation type and
  /// default points from the configured category, so [points] / [category]
  /// become optional overrides.
  Future<bool> mutatePoints({
    required bool isAdd,
    int? points,
    String? category,
    int? categoryId,
    String? reason,
    String? notes,
    DateTime? pointsDate,
  }) async {
    if (!hasEmployee) return false;
    isMutating.value = true;
    try {
      String? formattedDate;
      if (pointsDate != null) {
        formattedDate =
            '${pointsDate.year.toString().padLeft(4, '0')}-${pointsDate.month.toString().padLeft(2, '0')}-${pointsDate.day.toString().padLeft(2, '0')}';
      }
      final result = await mutateUsecase.call(
        employeeId: currentEmployeeId.value,
        isAdd: isAdd,
        points: points,
        category: category,
        categoryId: categoryId,
        reason: reason,
        notes: notes,
        pointsDate: formattedDate,
      );
      return result.fold(
        (failure) {
          Get.snackbar('error'.tr, failure.errMessage,
              snackPosition: SnackPosition.BOTTOM);
          return false;
        },
        (log) async {
          await Future.wait([
            loadMonthlySummary(),
            loadLogs(reset: true),
          ]);
          Get.snackbar(
            'success'.tr,
            'pointsUpdatedMessage'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F5E9),
            colorText: const Color(0xFF1B5E20),
          );
          return true;
        },
      );
    } finally {
      isMutating.value = false;
    }
  }

  /// All categories (positive + negative) for picker dropdowns.
  List<String> allCategories() {
    final c = categories.value;
    if (c == null) return const [];
    return [...c.positive, ...c.negative];
  }

  bool isPositiveCategory(String key) {
    final c = categories.value;
    if (c == null) return true;
    return c.positive.contains(key);
  }
}
