import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../routes/app_routes.dart';
import '../controllers/employee_section_controller.dart';
import '../widgets/employee_list.dart';
import '../widgets/titles.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
            SizedBox(height: 20.h),
            // العناوين
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: titles(context, controller),
            ),
            SizedBox(height: 15.h),
            // employee List
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: employeeList(controller),
            ),
          ],
        ),
      ),
    );
  }
}
