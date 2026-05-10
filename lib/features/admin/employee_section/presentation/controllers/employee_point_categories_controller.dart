import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_points_log_model.dart';
import '../../domain/usecases/employee_points_usecases.dart';

/// Controller for the admin "Point Categories Settings" screen.
class EmployeePointCategoriesController extends GetxController {
  EmployeePointCategoriesController({
    required this.fetchUsecase,
    required this.createUsecase,
    required this.updateUsecase,
    required this.deleteUsecase,
  });

  final GetEmployeePointCategoriesUsecase fetchUsecase;
  final CreateEmployeePointCategoryUsecase createUsecase;
  final UpdateEmployeePointCategoryUsecase updateUsecase;
  final DeleteEmployeePointCategoryUsecase deleteUsecase;

  final RxList<EmployeePointCategoryModel> categories =
      <EmployeePointCategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isMutating = false.obs;
  final RxnString errorMessage = RxnString();

  // Local filter for the screen (positive / negative / all).
  final RxnString filterOperationType = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      categories.assignAll(
        await fetchUsecase.call(operationType: filterOperationType.value),
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

  void setOperationFilter(String? value) {
    filterOperationType.value = (value == null || value.isEmpty) ? null : value;
    loadCategories();
  }

  List<EmployeePointCategoryModel> get positiveCategories =>
      categories.where((c) => c.isAdd).toList();

  List<EmployeePointCategoryModel> get negativeCategories =>
      categories.where((c) => c.isDeduct).toList();

  Future<bool> createCategory({
    required String nameAr,
    String? nameEn,
    required String code,
    required String operationType,
    required int defaultPoints,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    isMutating.value = true;
    try {
      final result = await createUsecase.call(
        nameAr: nameAr,
        nameEn: nameEn,
        code: code,
        operationType: operationType,
        defaultPoints: defaultPoints,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      return result.fold(
        (failure) {
          Get.snackbar('error'.tr, failure.errMessage,
              snackPosition: SnackPosition.BOTTOM);
          return false;
        },
        (_) {
          loadCategories();
          Get.snackbar(
            'success'.tr,
            'pointCategoryCreated'.tr,
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

  Future<bool> updateCategory({
    required int id,
    String? nameAr,
    String? nameEn,
    String? code,
    String? operationType,
    int? defaultPoints,
    bool? isActive,
    int? sortOrder,
  }) async {
    isMutating.value = true;
    try {
      final result = await updateUsecase.call(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        code: code,
        operationType: operationType,
        defaultPoints: defaultPoints,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      return result.fold(
        (failure) {
          Get.snackbar('error'.tr, failure.errMessage,
              snackPosition: SnackPosition.BOTTOM);
          return false;
        },
        (cat) {
          final index = categories.indexWhere((c) => c.id == cat.id);
          if (index >= 0) {
            categories[index] = cat;
          } else {
            loadCategories();
          }
          Get.snackbar(
            'success'.tr,
            'pointCategoryUpdated'.tr,
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

  Future<bool> toggleActive(EmployeePointCategoryModel category) {
    return updateCategory(id: category.id, isActive: !category.isActive);
  }

  Future<bool> deleteCategory(int id) async {
    isMutating.value = true;
    try {
      final result = await deleteUsecase.call(id: id);
      return result.fold(
        (failure) {
          Get.snackbar('error'.tr, failure.errMessage,
              snackPosition: SnackPosition.BOTTOM);
          return false;
        },
        (_) {
          categories.removeWhere((c) => c.id == id);
          Get.snackbar(
            'success'.tr,
            'pointCategoryDeleted'.tr,
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
}
