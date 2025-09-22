import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/employee_task_model.dart';
import '../controllers/employee_tasks_controller.dart';

class EmployeeTasksLists extends StatelessWidget {
  const EmployeeTasksLists({
    Key? key,
    required this.controller,
    required this.order,
    required this.index,
  }) : super(key: key);

  final EmployeeTasksController controller;
  final EmployeeTaskModel order;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      children: [
        SizedBox(height: 8.h),
        GestureDetector(
          onLongPress: () => controller.currentTab.value == 0
              ? Get.dialog(
                  AlertDialog(
                    backgroundColor: ThemeService.isDark.value
                        ? AppColors.darkColor
                        : AppColors.whiteColor,
                    content: Obx(
                      () => controller.isLoading.value
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  heightFactor: 3.7.h,
                                  child: const CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomCheckBox(
                                  title: 'deleteTask',
                                  value: controller.deleteTask,
                                  onChanged: (value) {
                                    controller.deleteTask.value = value!;
                                    controller.deleteTasDuplicate.value = false;
                                  },
                                  style: theme.copyWith(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? Colors.white
                                        : AppColors.secondaryColor,
                                  ),
                                ),
                                CustomCheckBox(
                                  title: 'deleteRepeatedTask',
                                  value: controller.deleteTasDuplicate,
                                  onChanged: (value) {
                                    controller.deleteTasDuplicate.value =
                                        value!;
                                    controller.deleteTask.value = false;
                                  },
                                  style: theme.copyWith(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? Colors.white
                                        : AppColors.secondaryColor,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                AppButton(
                                  text: 'save',
                                  onPressed: () =>
                                      controller.deleteTask.value == false &&
                                              controller.deleteTasDuplicate
                                                      .value ==
                                                  false
                                          ? null
                                          : controller.cancelEmployeeTask(
                                              taskId: order.taskId.toString(),
                                              cancelWithRepetition: controller
                                                  .deleteTasDuplicate.value,
                                            ),
                                ),
                              ],
                            ),
                    ),
                  ),
                )
              : null,
          onTap: () {
            controller.getTaskDetails(taskId: order.taskId.toString());
            Get.toNamed(AppRoutes.TASKDETAILS);
          },
          child: Container(
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.r),
                    child: CachedNetworkImage(
                      imageUrl: order.adminImg!,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      fit: BoxFit.cover,
                      width: 55.w,
                      height: 55.h,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              order.taskName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: ThemeService.isDark.value
                                    ? AppColors.whiteColor
                                    : AppColors.customGreyColor5,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              showData(order.endTime),
                              style: theme.copyWith(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: ThemeService.isDark.value
                                    ? AppColors.whiteColor
                                    : AppColors.customGreyColor5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        order.employeeName,
                        style: theme.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.customGreyColor5,
                        ),
                      ),
                    ],
                  ),
                ),
                controller.currentTab.value == 2
                    ? SizedBox(height: 75.h, width: 90.w)
                    : Container(
                        width: 70.w,
                        height: 70.h,
                        decoration: BoxDecoration(
                          color:
                              order.endTime.difference(DateTime.now()).inHours >
                                      2
                                  ? AppColors.customGreen1
                                  : order.endTime
                                              .difference(DateTime.now())
                                              .inHours >
                                          0
                                      ? AppColors.customOrange3
                                      : AppColors.redColor,
                          borderRadius: Get.locale!.languageCode == 'en'
                              ? BorderRadius.only(
                                  topRight: Radius.circular(4.r),
                                  bottomRight: Radius.circular(4.r),
                                )
                              : BorderRadius.only(
                                  topLeft: Radius.circular(4.r),
                                  bottomLeft: Radius.circular(4.r),
                                ),
                        ),
                        margin: Get.locale!.languageCode == 'en'
                            ? EdgeInsets.only(left: 30.w)
                            : EdgeInsets.only(right: 30.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              order.endTime
                                  .difference(DateTime.now())
                                  .inHours
                                  .toString(),
                              textAlign: TextAlign.center,
                              style: theme.copyWith(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              order.endTime.difference(DateTime.now()).inHours >
                                          10 ||
                                      order.endTime
                                              .difference(DateTime.now())
                                              .inHours <
                                          -10
                                  ? 'hour'.tr
                                  : 'hours'.tr,
                              style: theme.copyWith(
                                fontSize: 12.sp,
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
        ),
      ],
    );
  }
}
