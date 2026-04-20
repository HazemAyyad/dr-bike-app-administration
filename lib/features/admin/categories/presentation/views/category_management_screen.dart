import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/sub_category_model.dart';
import '../controllers/category_management_controller.dart';
import '../widgets/add_edit_category_dialog.dart';
import '../widgets/add_edit_sub_category_dialog.dart';

class CategoryManagementScreen extends GetView<CategoryManagementController> {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'categoryManagement'.tr,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'refresh'.tr,
            onPressed: () => controller.loadCategories(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: SearchBar(
              controller: controller.searchController,
              shadowColor: WidgetStateProperty.all(Colors.transparent),
              leading: const Icon(Icons.search),
              hintText: 'search'.tr,
              backgroundColor: WidgetStateProperty.all(
                isDark ? AppColors.customGreyColor : AppColors.customGreyColor7,
              ),
              onChanged: controller.filterCategories,
            ),
          ),
          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: GetBuilder<CategoryManagementController>(
              builder: (ctrl) {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.filteredCategories.isEmpty) {
                  return Center(
                    child: Text(
                      'noCategories'.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14.sp,
                            color: isDark
                                ? AppColors.customGreyColor6
                                : AppColors.secondaryColor,
                          ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ctrl.loadCategories(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    itemCount: ctrl.filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = ctrl.filteredCategories[index];
                      return _CategoryCard(category: category);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // ── FAB: add category ───────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddEditCategoryDialog(controller: controller),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: Get.locale?.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Category card
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryCard extends GetView<CategoryManagementController> {
  const _CategoryCard({required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return GetBuilder<CategoryManagementController>(
      builder: (ctrl) {
        final isExpanded = ctrl.expandedIds.contains(category.id);
        final isLoadingSubs = ctrl.loadingSubIds.contains(category.id);
        final subs = ctrl.subCategoriesMap[category.id] ?? [];

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(60),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Category row ───────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    // expand toggle
                    GestureDetector(
                      onTap: () => ctrl.toggleExpand(category.id),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right,
                          color: AppColors.primaryColor,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // thumbnail
                    _Thumbnail(imageUrl: category.imageUrl, size: 40.w),
                    SizedBox(width: 8.w),
                    // name + id + badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.nameAr,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                  color: isDark
                                      ? AppColors.whiteColor
                                      : AppColors.secondaryColor,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Text(
                                '#${category.id}',
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: 10.sp,
                                      color: Colors.grey,
                                    ),
                              ),
                              SizedBox(width: 8.w),
                              _StatusBadge(isShow: category.isShow),
                              SizedBox(width: 8.w),
                              _CountBadge(
                                count: category.subCategoriesCount,
                                label: 'sub'.tr,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ── Action buttons ─────────────────────────────────────
                    // Toggle status
                    GestureDetector(
                      onTap: () => ctrl.toggleCategoryStatus(category.id),
                      child: Icon(
                        category.isShow
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: category.isShow ? Colors.green : Colors.grey,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Edit
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AddEditCategoryDialog(
                          controller: ctrl,
                          category: category,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Add subcategory
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AddEditSubCategoryDialog(
                          controller: ctrl,
                          mainCategoryId: category.id,
                          mainCategoryName: category.nameAr,
                        ),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: Colors.orange,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Subcategories panel ────────────────────────────────────
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: Colors.grey.withAlpha(80),
                  indent: 12.w,
                  endIndent: 12.w,
                ),
                if (isLoadingSubs)
                  Padding(
                    padding: EdgeInsets.all(12.h),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (subs.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(12.h),
                    child: Text(
                      'noSubCategories'.tr,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.grey,
                            fontSize: 12.sp,
                          ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subs.length,
                    itemBuilder: (context, i) => _SubCategoryRow(
                      sub: subs[i],
                      controller: ctrl,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Subcategory row
// ═══════════════════════════════════════════════════════════════════════════════

class _SubCategoryRow extends StatelessWidget {
  const _SubCategoryRow({
    required this.sub,
    required this.controller,
  });

  final SubCategoryModel sub;
  final CategoryManagementController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right,
              size: 16.sp, color: Colors.grey),
          SizedBox(width: 6.w),
          _Thumbnail(imageUrl: sub.imageUrl, size: 34.w),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.nameAr,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.whiteColor
                            : AppColors.secondaryColor,
                      ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      '#${sub.id}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontSize: 10.sp, color: Colors.grey),
                    ),
                    SizedBox(width: 6.w),
                    _StatusBadge(isShow: sub.isShow, small: true),
                  ],
                ),
              ],
            ),
          ),
          // Toggle subcategory status
          GestureDetector(
            onTap: () => controller.toggleSubCategoryStatus(
                sub.id, sub.mainCategoryId),
            child: Icon(
              sub.isShow ? Icons.visibility : Icons.visibility_off,
              color: sub.isShow ? Colors.green : Colors.grey,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          // Edit subcategory
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => AddEditSubCategoryDialog(
                controller: controller,
                subCategory: sub,
                mainCategoryId: sub.mainCategoryId,
                mainCategoryName: '',
              ),
            ),
            child: Icon(Icons.edit, color: AppColors.primaryColor, size: 18.sp),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor2 : AppColors.customGreyColor7,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: size * 0.45,
          color: Colors.grey,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: CachedNetworkImage(
        imageUrl: ShowNetImage.getPhoto(imageUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          color: isDark ? AppColors.customGreyColor2 : AppColors.customGreyColor7,
          child: Icon(Icons.broken_image_outlined,
              size: size * 0.45, color: Colors.grey),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isShow, this.small = false});

  final bool isShow;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 5.w : 6.w, vertical: small ? 1.h : 2.h),
      decoration: BoxDecoration(
        color: isShow ? Colors.green.withAlpha(40) : Colors.grey.withAlpha(40),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        isShow ? 'active'.tr : 'inactive'.tr,
        style: TextStyle(
          fontSize: small ? 8.sp : 9.sp,
          fontWeight: FontWeight.w600,
          color: isShow ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withAlpha(30),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
