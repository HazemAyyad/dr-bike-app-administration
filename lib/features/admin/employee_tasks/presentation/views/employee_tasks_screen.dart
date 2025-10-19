import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/routes/app_routes.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_tasks_controller.dart';
import '../widgets/employee_tasks_list.dart';

class EmployeeTasksScreen extends GetView<EmployeeTasksController> {
  const EmployeeTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeTasks'.tr,
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        employeeNameController: controller.employeeNameController,
        onPressedFilter: () {
          controller.filterEmployeeTasks();
          Get.back();
        },
        action: false,
      ),
      body: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: GetBuilder<EmployeeTasksController>(
                builder: (controller) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => controller.changeWeek(false),
                        icon: const Icon(
                          Icons.arrow_circle_right_outlined,
                          color: AppColors.primaryColor,
                          size: 35,
                        ),
                      ),
                      Text(
                        "من ${DateFormat('d/M/yyyy').format(controller.startDate)} "
                        "الى ${DateFormat('d/M/yyyy').format(controller.endDate)}",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: ThemeService.isDark.value
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryColor,
                            ),
                      ),
                      IconButton(
                        onPressed: () => controller.changeWeek(true),
                        icon: const Icon(
                          Icons.arrow_circle_left_outlined,
                          color: AppColors.primaryColor,
                          size: 35,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const EmployeeTasks(),
          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: {'title': 'createNewEmployeeTask', 'isEdit': false},
          );
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
