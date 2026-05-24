import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_task_model.dart';
import '../controllers/employee_tasks_controller.dart';
import 'operational_task_card.dart';

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
        GestureDetector(
          onLongPress: () => controller.currentTab.value != controller.archiveTabIndex
              ? Get.dialog(
                  Dialog(
                    backgroundColor: ThemeService.isDark.value
                        ? AppColors.darkColor
                        : AppColors.whiteColor,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Obx(
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
                                      controller.deleteTasDuplicate.value =
                                          false;
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
                                    isSafeArea: false,
                                    text: 'save',
                                    onPressed: () =>
                                        controller.deleteTask.value == false &&
                                                controller.deleteTasDuplicate
                                                        .value ==
                                                    false
                                            ? null
                                            : controller.cancelEmployeeTask(
                                                taskId: order.taskId.toString(),
                                                occurrenceId: order.occurrenceId,
                                                cancelWithRepetition: controller
                                                    .deleteTasDuplicate.value,
                                              ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                )
              : null,
          onTap: () => controller.openTaskDetails(order),
          child: OperationalTaskCard(task: order),
        ),
      ],
    );
  }
}
