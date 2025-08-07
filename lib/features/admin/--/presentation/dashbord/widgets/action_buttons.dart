// بناء أزرار الوظائف
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../controllers/dashboard_controller.dart';

Widget buildActionButtons(
    {required DashboardController controller, required BuildContext context}) {
  // قائمة بجميع الأزرار
  return Column(
    children: [
      GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5.h,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 16.h,
        ),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: controller.buttons.length,
        itemBuilder: (context, index) {
          return _buildActionButton(
            controller.buttons[index]['title'],
            controller.buttons[index]['route'],
          );
        },
      ),
      SizedBox(height: 16.h),
      // زر المصاريف والأمور المالية (عرض كامل)
      Container(
        height: 45.h,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            'financialMatters'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    ],
  );
}

// بناء زر وظيفة واحد
Widget _buildActionButton(String title, String route) {
  return GestureDetector(
    onTap: () {
      // print(route);
      route == '' ? null : Get.toNamed(route);
    },
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                title.tr,
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
