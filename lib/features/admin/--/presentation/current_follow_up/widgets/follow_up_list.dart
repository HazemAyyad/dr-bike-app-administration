import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';

Obx followUpList(controller) {
  return Obx(
    () => AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: ListView.builder(
        shrinkWrap: true,
        key: ValueKey<int>(controller.currentTab.value),
        itemCount: controller.tasks.length,
        itemBuilder: (context, index) {
          final order = controller.tasks[index];
          return SizedBox(
            // height: 45.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10.w),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                      child: SizedBox(
                        width: 60.w,
                        child: Text(
                          order['customerName'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.customGreyColor5,
                                  ),
                        ),
                      ),
                    ),
                    Text(
                      '${order['productDetails']}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.customGreyColor5,
                          ),
                    ),
                    Text(
                      '${order['startDate']}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.customGreyColor5,
                          ),
                    ),
                    if (controller.currentTab.value == 0)
                      GestureDetector(
                        onTap: () {
                          // Handle cancel order action
                          print('Cancel ${order['customerName']}');
                        },
                        child: Container(
                          height: 24.h,
                          width: 80.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor2
                                  : AppColors.secondaryColor,
                              width: 1.w,
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Center(
                            child: Text(
                              'notifyCustomer'.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w400,
                                    color: ThemeService.isDark.value
                                        ? AppColors.customGreyColor2
                                        : AppColors.secondaryColor,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    if (controller.currentTab.value == 0)
                      GestureDetector(
                        onTap: () {
                          // Handle cancel order action
                          print('Cancel ${order['customerName']}');
                        },
                        child: Container(
                          height: 24.h,
                          width: 65.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red,
                              width: 1.w,
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Center(
                            child: Text(
                              'cancelFollowUp'.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.red,
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.w),
                Divider(
                  color: const Color.fromRGBO(217, 217, 217, 1),
                  thickness: 1.h,
                  // height: 20.h,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
