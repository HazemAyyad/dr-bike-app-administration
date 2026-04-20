import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/category_model.dart';
import '../../data/models/sub_category_model.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/save_category_usecase.dart';
import '../../domain/usecases/save_sub_category_usecase.dart';

class CategoryManagementController extends GetxController {
  final GetCategoriesUsecase getCategoriesUsecase;
  final SaveCategoryUsecase saveCategoryUsecase;
  final ToggleCategoryStatusUsecase toggleCategoryStatusUsecase;
  final GetSubCategoriesUsecase getSubCategoriesUsecase;
  final SaveSubCategoryUsecase saveSubCategoryUsecase;
  final ToggleSubCategoryStatusUsecase toggleSubCategoryStatusUsecase;

  CategoryManagementController({
    required this.getCategoriesUsecase,
    required this.saveCategoryUsecase,
    required this.toggleCategoryStatusUsecase,
    required this.getSubCategoriesUsecase,
    required this.saveSubCategoryUsecase,
    required this.toggleSubCategoryStatusUsecase,
  });

  // ── State ───────────────────────────────────────────────────────────────────

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// categoryId → list of its subcategories (lazy loaded on expand).
  final Map<int, RxList<SubCategoryModel>> subCategoriesMap = {};

  /// which category rows are currently expanded.
  final RxSet<int> expandedIds = <int>{}.obs;

  /// which category rows are loading their subcategories.
  final RxSet<int> loadingSubIds = <int>{}.obs;

  // ── Search ──────────────────────────────────────────────────────────────────
  final RxList<CategoryModel> filteredCategories = <CategoryModel>[].obs;
  final TextEditingController searchController = TextEditingController();

  void filterCategories(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredCategories.assignAll(categories);
    } else {
      filteredCategories.assignAll(
        categories.where((c) =>
            c.nameAr.toLowerCase().contains(q) ||
            c.nameEng.toLowerCase().contains(q) ||
            c.id.toString().contains(q)),
      );
    }
    update();
  }

  // ── Load categories ─────────────────────────────────────────────────────────

  Future<void> loadCategories({bool silent = false}) async {
    if (!silent) {
      isLoading(true);
      update();
    }
    try {
      final result = await getCategoriesUsecase.call();
      categories.assignAll(result);
      filteredCategories.assignAll(result);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading(false);
      update();
    }
  }

  // ── Expand / collapse ────────────────────────────────────────────────────────

  Future<void> toggleExpand(int categoryId) async {
    if (expandedIds.contains(categoryId)) {
      expandedIds.remove(categoryId);
      update();
      return;
    }
    expandedIds.add(categoryId);
    // Load subs if not cached
    if (!(subCategoriesMap[categoryId]?.isNotEmpty ?? false)) {
      await _loadSubCategories(categoryId);
    }
    update();
  }

  Future<void> _loadSubCategories(int categoryId) async {
    loadingSubIds.add(categoryId);
    update();
    try {
      final subs = await getSubCategoriesUsecase.call(categoryId: categoryId);
      subCategoriesMap[categoryId] = RxList<SubCategoryModel>(subs);
    } catch (_) {
      subCategoriesMap[categoryId] = RxList<SubCategoryModel>([]);
    } finally {
      loadingSubIds.remove(categoryId);
      update();
    }
  }

  // ── Save category ────────────────────────────────────────────────────────────

  Future<void> saveCategory({
    BuildContext? context,
    int? categoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    XFile? image,
  }) async {
    if (nameAr.trim().isEmpty) {
      Get.snackbar('error'.tr, 'catNameArRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    isSaving(true);
    update();
    try {
      final result = await saveCategoryUsecase.call(
        categoryId: categoryId,
        nameAr: nameAr.trim(),
        nameEng: nameEng.trim(),
        nameAbree: nameAbree.trim(),
        image: image,
      );
      if (result['status'] == 'success') {
        Get.back(); // close dialog
        await loadCategories(silent: true);
        Get.snackbar(
          'success'.tr,
          result['message'] ?? 'success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withAlpha(200),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'error'.tr,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving(false);
      update();
    }
  }

  // ── Toggle category status ───────────────────────────────────────────────────

  Future<void> toggleCategoryStatus(int categoryId) async {
    try {
      final result = await toggleCategoryStatusUsecase.call(categoryId: categoryId);
      if (result['status'] == 'success') {
        final newStatus = result['isShow'] as bool;
        final idx = categories.indexWhere((c) => c.id == categoryId);
        if (idx != -1) {
          categories[idx] = categories[idx].copyWith(isShow: newStatus);
          filteredCategories.assignAll(categories);
          update();
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Save subcategory ─────────────────────────────────────────────────────────

  Future<void> saveSubCategory({
    int? subCategoryId,
    required String nameAr,
    required String nameEng,
    required String nameAbree,
    required int mainCategoryId,
    XFile? image,
  }) async {
    if (nameAr.trim().isEmpty) {
      Get.snackbar('error'.tr, 'catNameArRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    isSaving(true);
    update();
    try {
      final result = await saveSubCategoryUsecase.call(
        subCategoryId: subCategoryId,
        nameAr: nameAr.trim(),
        nameEng: nameEng.trim(),
        nameAbree: nameAbree.trim(),
        mainCategoryId: mainCategoryId,
        image: image,
      );
      if (result['status'] == 'success') {
        Get.back(); // close dialog
        // Refresh subcategories for this category
        subCategoriesMap.remove(mainCategoryId);
        if (expandedIds.contains(mainCategoryId)) {
          await _loadSubCategories(mainCategoryId);
        }
        // Update sub count in category list
        await loadCategories(silent: true);
        Get.snackbar(
          'success'.tr,
          result['message'] ?? 'success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withAlpha(200),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'error'.tr,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving(false);
      update();
    }
  }

  // ── Toggle subcategory status ────────────────────────────────────────────────

  Future<void> toggleSubCategoryStatus(int subCategoryId, int mainCategoryId) async {
    try {
      final result =
          await toggleSubCategoryStatusUsecase.call(subCategoryId: subCategoryId);
      if (result['status'] == 'success') {
        final newStatus = result['isShow'] as bool;
        final subs = subCategoriesMap[mainCategoryId];
        if (subs != null) {
          final idx = subs.indexWhere((s) => s.id == subCategoryId);
          if (idx != -1) {
            subs[idx] = subs[idx].copyWith(isShow: newStatus);
            update();
          }
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
