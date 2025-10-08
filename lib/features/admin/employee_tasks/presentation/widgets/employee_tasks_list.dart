import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_task_model.dart';
import '../controllers/employee_tasks_controller.dart';
import 'employee_tasks_lists.dart';

class EmployeeTasks extends GetView<EmployeeTasksController> {
  const EmployeeTasks({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    return GetBuilder<EmployeeTasksController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        }
        if (controller.currentTab.value == 0 &&
            controller.ongoingTasksFilter.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: ShowNoData(),
          );
        }
        if (controller.currentTab.value == 1 &&
            controller.completedTasksFilter.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: ShowNoData(),
          );
        }
        if (controller.currentTab.value == 2 &&
            controller.canceledTasksFilter.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: ShowNoData(),
          );
        }
        return SliverList.builder(
          itemCount: controller.currentTab.value == 0
              ? controller.ongoingTasksFilter.length
              : controller.currentTab.value == 1
                  ? controller.completedTasksFilter.length
                  : controller.canceledTasksFilter.length,
          itemBuilder: (context, index) {
            final month = controller.currentTab.value == 0
                ? controller.ongoingTasksFilter.keys.toList()[index]
                : controller.currentTab.value == 1
                    ? controller.completedTasksFilter.keys.toList()[index]
                    : controller.canceledTasksFilter.keys.toList()[index];
            List<EmployeeTaskModel> date = controller.currentTab.value == 0
                ? controller.ongoingTasksFilter[month]!.reversed.toList()
                : controller.currentTab.value == 1
                    ? controller.completedTasksFilter[month]!.reversed.toList()
                    : controller.canceledTasksFilter[month]!.reversed.toList();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('EEEE, yyyy/MM/dd', Get.locale!.languageCode)
                            .format(DateTime.parse(month)),
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
                  ...date.map(
                    (order) {
                      return EmployeeTasksLists(
                        controller: controller,
                        order: order,
                        index: index,
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
