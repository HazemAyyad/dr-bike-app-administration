import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';

class AddList extends GetView<SalesController> {
  const AddList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: Get.locale!.languageCode == 'ar' ? 0 : 150.w,
      right: Get.locale!.languageCode == 'ar' ? 150.w : 0,
      child: SizeTransition(
        sizeFactor: controller.sizeAnimation,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: controller.opacityAnimation,
          child: Container(
            margin: EdgeInsets.all(5.h),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 3,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'add'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: 8.h),
                ...controller.addList.map(
                  (item) => BuildAddMenuItem(
                    title: item['title']!,
                    iconAsset: item['icon']!,
                    route: item['route']!,
                    onTap: () => controller.toggleAddMenu(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
