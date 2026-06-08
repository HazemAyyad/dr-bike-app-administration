import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/product_management_controller.dart';

class ProductManagementToolbar extends GetView<ProductManagementController> {
  const ProductManagementToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.search,
              onChanged: controller.onSearchChanged,
              style: textTheme.copyWith(
                fontSize: 15.sp,
                color: ThemeService.isDark.value
                    ? AppColors.whiteColor
                    : AppColors.secondaryColor,
              ),
              decoration: InputDecoration(
                hintText: 'search'.tr,
                hintStyle: textTheme.copyWith(
                  color: AppColors.customGreyColor5,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                  size: 22.sp,
                ),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: controller.clearSearch,
                  );
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12.w,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => Tooltip(
              message: controller.sortDescending.value
                  ? 'developmentSortDesc'.tr
                  : 'developmentSortAsc'.tr,
              child: Material(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: controller.toggleSortOrder,
                  child: SizedBox(
                    width: 44.w,
                    height: 44.w,
                    child: Icon(
                      controller.sortDescending.value
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: AppColors.secondaryColor,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
