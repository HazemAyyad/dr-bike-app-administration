import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/routes/app_routes.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
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
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: {'title': 'createNewEmployeeTask', 'isEdit': false},
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          EmployeeTasks(controller: controller),
          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }
}
