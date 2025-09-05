import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/special_tasks_controller.dart';
import '../widgets/tasks_list.dart';

class SpecialTasksScreen extends GetView<SpecialTasksController> {
  const SpecialTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'privateTasks',
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedFilter: () => controller.filterLists(true),
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: {'title': 'addNewPravateTask', 'isEdit': false},
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          TasksList(),
          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }
}
