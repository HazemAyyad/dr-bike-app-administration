import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeDashbordTasks extends GetView<EmployeeDashbordController> {
  const EmployeeDashbordTasks({Key? key, required this.task}) : super(key: key);

  final Task task;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.TASKDETAILS,
          arguments: {
            'taskId': task.id.toString(),
            'EmployeeDashbordController': controller
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.scale(
              scale: 1.5,
              child: Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                side: const BorderSide(color: AppColors.primaryColor),
                value: task.status == 'completed',
                onChanged: (value) {
                  if (value == true) {
                    Get.dialog(
                      Dialog(
                        backgroundColor: ThemeService.isDark.value
                            ? AppColors.darkColor
                            : AppColors.whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 5.h),
                              Text(
                                'areYouSure'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Flexible(
                                    child: AppButton(
                                      isSafeArea: false,
                                      isLoading: controller.isTaskLoading,
                                      width: double.infinity,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.r),
                                      ),
                                      text: 'yes'.tr,
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      onPressed: () {
                                        controller.changeTaskToCompleted(
                                          context: context,
                                          isSubTask: false,
                                          taskId: task.id,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Flexible(
                                    child: AppButton(
                                      isLoading: controller.isTaskLoading,
                                      isSafeArea: false,
                                      color: Colors.red,
                                      width: double.infinity,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.r),
                                      ),
                                      text: 'cancel'.tr,
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      onPressed: () {
                                        Get.back();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: Text(
                task.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor7
                          : AppColors.customGreyColor4,
                    ),
              ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: 5.w),
            Text(
              showData(task.endTime),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor7
                        : AppColors.customGreyColor4,
                  ),
            ),
            SizedBox(width: 5.w),
            controller.currentTab.value == 1
                ? SizedBox(height: 40.h)
                : const SizedBox.shrink(),
            controller.currentTab.value == 1
                ? const SizedBox.shrink()
                : Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: task.endTime.difference(DateTime.now()).inHours > 2
                          ? AppColors.customGreen1
                          : task.endTime.difference(DateTime.now()).inHours > 0
                              ? AppColors.customOrange3
                              : AppColors.redColor,
                      borderRadius: Get.locale!.languageCode == 'en'
                          ? BorderRadius.only(
                              topRight: Radius.circular(9.r),
                              bottomRight: Radius.circular(9.r),
                            )
                          : BorderRadius.only(
                              topLeft: Radius.circular(9.r),
                              bottomLeft: Radius.circular(9.r),
                            ),
                    ),
                    // margin: Get.locale!.languageCode == 'en'
                    //     ? EdgeInsets.only(left: 5.w)
                    //     : EdgeInsets.only(right: 5.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          task.endTime
                              .difference(DateTime.now())
                              .inHours
                              .toString(),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                        ),
                        // SizedBox(height: 5.h),
                        Text(
                          task.endTime.difference(DateTime.now()).inHours >
                                      10 ||
                                  task.endTime
                                          .difference(DateTime.now())
                                          .inHours <
                                      -10
                              ? 'hour'.tr
                              : 'hours'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
