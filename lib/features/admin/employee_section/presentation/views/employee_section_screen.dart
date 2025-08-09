import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/employee_section_controller.dart';
import '../widgets/employee_section.dart';

class EmployeeSectionScreen extends GetView<EmployeeSectionController> {
  const EmployeeSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        title: 'employeeSection',
        toDateController: controller.toDateController,
        fromDateController: controller.fromDateController,
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(
            AppRoutes.ADDNEWEMPLOYEESCREEN,
            arguments: {'title': 'addNewEmployee'},
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
          EmployeeSection(controller: controller),
        ],
      ),
    );
  }
}
