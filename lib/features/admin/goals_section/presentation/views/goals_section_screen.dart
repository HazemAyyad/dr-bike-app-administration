import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../controllers/target_section_controller.dart';
import '../widgets/goals_view.dart';

class GoalsSectionScreen extends GetView<TargetSectionController> {
  const GoalsSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'targetSection',
        toDateController: controller.toDateController,
        fromDateController: controller.fromDateController,
        action: false,
        onPressedFilter: () => controller.filterGoals(),
      ),
      body: CustomScrollView(
        slivers: [
          // targets tab bar
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          const GoalsView(),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          controller.reset();
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
