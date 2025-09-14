import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/project_controller.dart';
import '../widgets/project_manag_view.dart';

class ProjectScreen extends GetView<ProjectController> {
  const ProjectScreen({Key? key}) : super(key: key);

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
        ],
      ),
    );
  }
}
