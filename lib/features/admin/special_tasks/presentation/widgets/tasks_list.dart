import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_calendar.dart';
import 'package:doctorbike/features/admin/special_tasks/data/models/special_task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/special_tasks_controller.dart';

class TasksList extends GetView<SpecialTasksController> {
  const TasksList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;

    return Obx(
      () {
        if (controller.isLoading.value) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        } else if (controller.filteredTasks.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 200.h),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 100.h,
                    color: AppColors.graywhiteColor,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'noData'.tr,
                    style: theme.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.graywhiteColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList.builder(
          itemCount: controller.filteredTasks.length,
          itemBuilder: (context, index) {
            String date = controller.filteredTasks.keys.toList()[index];
            List<SpecialTaskModel> tasksForDate =
                controller.filteredTasks[date]!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
              child: Column(
                children: [
                  controller.currentTab.value == 1
                      ? SizedBox.shrink()
                      : Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  date,
                                  style: theme.copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Container(
                              height: 1.h,
                              width: double.infinity,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ),
                  ...tasksForDate.map(
                    (task) {
                      final String key = task.id.toString();
                      controller.checkedMap.putIfAbsent(key, () => false.obs);

                      return GestureDetector(
                        onLongPress: () => controller.currentTab.value == 0
                            ? Get.dialog(
                                Dialog(
                                  // backgroundColor: Colors.transparent,
                                  child: Container(
                                    padding: EdgeInsets.all(20.h),
                                    decoration: BoxDecoration(
                                      // color: ThemeService.isDark.value
                                      //     ? AppColors.customGreyColor4
                                      //     : AppColors.whiteColor2,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomCheckBox(
                                          title: 'transferTask',
                                          style: theme.copyWith(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          value: controller.transferTask,
                                          onChanged: (val) {
                                            controller
                                                .setOnlyOneTrue('transferTask');
                                          },
                                          shape: const CircleBorder(),
                                        ),
                                        Obx(
                                          () => controller.transferTask.value
                                              ? CustomCalendar(
                                                  isVisible:
                                                      controller.transferTask,
                                                  onTap: () {},
                                                  selectedDay:
                                                      controller.selectedDay,
                                                )
                                              : SizedBox.shrink(),
                                        ),
                                        SizedBox(height: 3.h),
                                        CustomCheckBox(
                                          title: 'deleteTask',
                                          style: theme.copyWith(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          value: controller.deleteTask,
                                          onChanged: (val) {
                                            controller
                                                .setOnlyOneTrue('deleteTask');
                                          },
                                          shape: const CircleBorder(),
                                        ),
                                        SizedBox(height: 3.h),
                                        CustomCheckBox(
                                          title: 'deleteRepeatedTask',
                                          style: theme.copyWith(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          value: controller.deleteRepeatedTask,
                                          onChanged: (val) {
                                            controller.setOnlyOneTrue(
                                              'deleteRepeatedTask',
                                            );
                                          },
                                          shape: const CircleBorder(),
                                        ),
                                        SizedBox(height: 8.h),
                                        AppButton(
                                          isLoading: controller.isLoading,
                                          text: 'done',
                                          onPressed: () {
                                            controller.cancelSpecialTasks(
                                              specialTaskId: task.id.toString(),
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          controller.getSpecialTasksDetails(
                            specialTaskId: task.id.toString(),
                          );
                          Get.toNamed(AppRoutes.SPECIALTASKDETAILSSCREEN);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.all(5.h),
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor4
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.customGreyColor3,
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Flexible(
                                child: CustomCheckBox(
                                  title: task.name,
                                  style: theme.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w400,
                                    color: ThemeService.isDark.value
                                        ? Colors.white
                                        : AppColors.secondaryColor,
                                    decoration: controller.currentTab.value == 2
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    decorationColor: AppColors.customGreyColor,
                                    decorationThickness: 2,
                                  ),
                                  value: controller.currentTab.value == 2
                                      ? true.obs
                                      : controller
                                          .checkedMap[task.id.toString()]!,
                                  onChanged: (val) {
                                    controller.checkedMap[task.id.toString()]!
                                        .value = val!;
                                    controller.completedSpecialTasks(
                                        context, task.id.toString());
                                  },
                                  shape: const CircleBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
