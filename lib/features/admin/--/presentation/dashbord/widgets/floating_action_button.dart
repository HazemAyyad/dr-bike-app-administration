// بناء زر الإضافة وقائمته
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../routes/app_routes.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({required this.controller, Key? key})
      : super(key: key);

  final dynamic controller;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Get.locale!.languageCode == 'ar'
          ? Alignment.bottomLeft
          : Alignment.bottomRight,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Get.locale!.languageCode == 'ar'
              ? Alignment.bottomLeft
              : Alignment.bottomRight,
          children: [
            Obx(() {
              if (!controller.isAddMenuOpen.value) return SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: controller.toggleAddMenu,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              );
            }),

            Positioned(
              bottom: 40.h,
              left: Get.locale!.languageCode == 'ar' ? 0.w : 70.w,
              right: Get.locale!.languageCode == 'ar' ? 70.w : 0.w,
              child: SizeTransition(
                sizeFactor: controller.sizeAnimation,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: controller.opacityAnimation,
                  child: Container(
                    width: 306.w,
                    height: 211.h,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'add'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        SizedBox(height: 8.h),
                        buildAddMenuItem(
                          'newInvoice'.tr,
                          AssetsManger.invoiceIcon,
                          controller,
                          context,
                          AppRoutes.ADDNEWEMPLOYEESCREEN,
                        ),
                        buildAddMenuItem(
                            'newEmployee'.tr,
                            AssetsManger.userIcon,
                            controller,
                            context,
                            AppRoutes.ADDNEWEMPLOYEESCREEN),
                        buildAddMenuItem(
                            'newExpense'.tr,
                            AssetsManger.moneyIcon,
                            controller,
                            context,
                            AppRoutes.ADDNEWEMPLOYEESCREEN),
                        buildAddMenuItem(
                            'newCustomer'.tr,
                            AssetsManger.userIcon,
                            controller,
                            context,
                            AppRoutes.ADDNEWCUSTOMERSCREEN),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // زر الإضافة
            SizedBox(
              height: 55.h,
              width: 55.w,
              child: FloatingActionButton(
                onPressed: controller.toggleAddMenu,
                backgroundColor: AppColors.secondaryColor,
                elevation: 2.0,
                shape: CircleBorder(),
                child: Icon(Icons.add, color: Colors.white, size: 42.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// بناء عنصر قائمة إضافة واحد
Widget buildAddMenuItem(
  String title,
  String iconAsset,
  controller,
  BuildContext context,
  String route,
) {
  return InkWell(
    onTap: () {
      Get.toNamed(route, arguments: {
        'isNewCheck': title == 'newCheck',
      });
      controller.toggleAddMenu();
    },
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Image.asset(iconAsset, height: 24.h, width: 24.w)),
          SizedBox(width: 8.w),
          Text(
            title.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Get.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    ),
  );
}
