import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_task_model.dart';
import '../controllers/employee_tasks_controller.dart';
import 'employee_tasks_lists.dart';

class EmployeeTasks extends StatelessWidget {
  const EmployeeTasks({Key? key, required this.controller}) : super(key: key);

  final EmployeeTasksController controller;

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
        } else if (controller.employeeTasksFilter.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: ShowNoData(),
          );
        }
        return SliverList.builder(
          itemCount: controller.employeeTasksFilter.length,
          itemBuilder: (context, index) {
            final month = controller.employeeTasksFilter.keys.toList()[index];
            List<EmployeeTaskModel> date =
                controller.employeeTasksFilter[month]!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        month,
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
