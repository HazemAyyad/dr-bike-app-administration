import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_calendar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/features/admin/special_tasks/data/models/special_task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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

    return GetBuilder<SpecialTasksController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.currentTab.value == 0 &&
            controller.filteredWeeklyTasks.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        if (controller.currentTab.value == 1 &&
            controller.filteredNoDateTasks.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        if (controller.currentTab.value == 2 &&
            controller.filteredArchivedTasks.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        return SliverList.builder(
          itemCount: controller.currentTab.value == 0
              ? controller.filteredWeeklyTasks.length
              : controller.currentTab.value == 1
                  ? controller.filteredNoDateTasks.length
                  : controller.filteredArchivedTasks.length,
          itemBuilder: (context, index) {
            String date = controller.currentTab.value == 0
                ? controller.filteredWeeklyTasks.keys
                    .toList()
                    .reversed
                    .toList()[index]
                : controller.currentTab.value == 1
                    ? controller.filteredNoDateTasks.keys
                        .toList()
                        .reversed
                        .toList()[index]
                    : controller.filteredArchivedTasks.keys
                        .toList()
                        .reversed
                        .toList()[index];
            List<SpecialTaskModel> tasksForDate =
                controller.currentTab.value == 0
                    ? controller.filteredWeeklyTasks[date]!
                    : controller.currentTab.value == 1
                        ? controller.filteredNoDateTasks[date]!
                        : controller.filteredArchivedTasks[date]!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: index == 0 ? 20.h : 0.h),
                  controller.currentTab.value == 1
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  DateFormat('EEEE, yyyy/MM/dd',
                                          Get.locale!.languageCode)
                                      .format(DateTime.parse(date)),
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
                  tasksForDate.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'noData'.tr,
                            style: theme.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...tasksForDate.map(
                              (task) {
                                final String key = task.id.toString();
                                controller.checkedMap
                                    .putIfAbsent(key, () => false.obs);
                                return GestureDetector(
                                  onLongPress: () => Get.dialog(
                                    Dialog(
                                      child: Container(
                                        padding: EdgeInsets.all(20.h),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (controller.currentTab.value ==
                                                  0)
                                                CustomCheckBox(
                                                  title: 'transferTask',
                                                  style: theme.copyWith(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  value:
                                                      controller.transferTask,
                                                  onChanged: (val) {
                                                    controller.setOnlyOneTrue(
                                                        'transferTask');
                                                  },
                                                  shape: const CircleBorder(),
                                                ),
                                              if (controller.currentTab.value ==
                                                  0)
                                                Obx(
                                                  () => controller
                                                          .transferTask.value
                                                      ? CustomCalendar(
                                                          isVisible: controller
                                                              .transferTask,
                                                          onTap: () {},
                                                          selectedDay:
                                                              controller
                                                                  .selectedDay,
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              if (controller.currentTab.value ==
                                                  0)
                                                SizedBox(height: 3.h),
                                              CustomCheckBox(
                                                title: 'deleteTask',
                                                style: theme.copyWith(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                value: controller.deleteTask,
                                                onChanged: (val) {
                                                  controller.setOnlyOneTrue(
                                                      'deleteTask');
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
                                                value: controller
                                                    .deleteRepeatedTask,
                                                onChanged: (val) {
                                                  controller.setOnlyOneTrue(
                                                    'deleteRepeatedTask',
                                                  );
                                                },
                                                shape: const CircleBorder(),
                                              ),
                                              SizedBox(height: 8.h),
                                              AppButton(
                                                isSafeArea: false,
                                                isLoading: controller.isLoading,
                                                text: 'done',
                                                onPressed: () {
                                                  controller.cancelSpecialTasks(
                                                    specialTaskId:
                                                        task.id.toString(),
                                                  );
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    controller.getSpecialTasksDetails(
                                      specialTaskId: task.id.toString(),
                                    );
                                    Get.toNamed(
                                        AppRoutes.SPECIALTASKDETAILSSCREEN);
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
                                              decoration: controller
                                                          .currentTab.value ==
                                                      2
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                              decorationColor:
                                                  AppColors.customGreyColor,
                                              decorationThickness: 2,
                                            ),
                                            value:
                                                controller.currentTab.value == 2
                                                    ? true.obs
                                                    : controller.checkedMap[
                                                        task.id.toString()]!,
                                            onChanged: (val) {
                                              if (controller.currentTab.value ==
                                                  2) {
                                                return;
                                              }
                                              Get.dialog(
                                                Dialog(
                                                  backgroundColor: ThemeService
                                                          .isDark.value
                                                      ? AppColors.darkColor
                                                      : AppColors.whiteColor,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.r),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(15.w),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                'areYouSure'.tr,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 2,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium!
                                                                    .copyWith(
                                                                      fontSize:
                                                                          18.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: AppColors
                                                                          .primaryColor,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 20.h),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: AppButton(
                                                                isSafeArea:
                                                                    false,
                                                                isLoading:
                                                                    controller
                                                                        .isLoading,
                                                                text: 'yes',
                                                                onPressed: () {
                                                                  controller
                                                                      .checkedMap[task
                                                                          .id
                                                                          .toString()]!
                                                                      .value = val!;
                                                                  controller
                                                                      .completedSpecialTasks(
                                                                    context,
                                                                    task.id
                                                                        .toString(),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                width: 10.w),
                                                            Expanded(
                                                              child: AppButton(
                                                                isLoading:
                                                                    controller
                                                                        .isLoading,
                                                                isSafeArea:
                                                                    false,
                                                                color:
                                                                    Colors.red,
                                                                width: double
                                                                    .infinity,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .all(
                                                                  Radius
                                                                      .circular(
                                                                          8.r),
                                                                ),
                                                                text:
                                                                    'cancel'.tr,
                                                                textStyle: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium!
                                                                    .copyWith(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          15.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}
