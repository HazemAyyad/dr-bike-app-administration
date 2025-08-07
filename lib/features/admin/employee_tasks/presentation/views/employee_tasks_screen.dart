import 'package:flutter/material.dart';
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
      appBar: customAppBar(
        context,
        title: 'employeeTasks'.tr,
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        employeeNameController: controller.employeeNameController,
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: 'createNewEmployeeTask',
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: Center(
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
              ),
            ),
          ),
          EmployeeTasks(controller: controller),
        ],
      ),
    );
  }
}
