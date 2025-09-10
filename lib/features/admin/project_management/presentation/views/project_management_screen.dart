import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/project_management_controller.dart';
import '../widgets/project_manag_view.dart';

class ProjectManagementScreen extends GetView<ProjectManagementController> {
  const ProjectManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'projectManagement',
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedAdd: () {
          Get.toNamed(AppRoutes.CREATEPROJECTSCREEN);
        },
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: InkWell(
          child: Column(
            children: [
              // project Management tab bar
              AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
              ),
              SizedBox(height: 15.h),
              // project Management View
              const ProjectManagementView(),
            ],
          ),
        ),
      ),
    );
  }
}
