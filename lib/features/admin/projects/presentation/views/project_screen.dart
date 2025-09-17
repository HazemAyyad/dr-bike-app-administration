import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../controllers/project_controller.dart';
import '../widgets/project_view.dart';

class ProjectScreen extends GetView<ProjectController> {
  const ProjectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'projectManagement',
        employeeNameController: controller.employeeNameController,
        onPressedFilter: () => controller.searchProjects(),
        label: 'projectName',
        onPressedAdd: () => controller.clear(),
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
          const ProjectView(),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
    );
  }
}
