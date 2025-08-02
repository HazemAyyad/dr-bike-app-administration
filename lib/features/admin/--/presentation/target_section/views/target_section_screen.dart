import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../routes/app_routes.dart';
import '../controllers/target_section_controller.dart';
import '../widgets/targets_table.dart';
import '../widgets/view_targets.dart';

class TargetSectionScreen extends GetView<TargetSectionController> {
  const TargetSectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        title: 'targetSection',
        toDateController: controller.toDateController,
        fromDateController: controller.fromDateController,
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(AppRoutes.ADDNEWTARGETSCREEN);
        },
      ),
      body: Column(
        children: [
          // targets tab bar
          AppTabs(
            tabs: controller.tabs,
            currentTab: controller.currentTab,
            changeTab: controller.changeTab,
          ),
          SizedBox(height: 20.h),
          // targets table header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: targetsTable(context, controller),
          ),
          SizedBox(height: 15.h),
          // view targets
          viewTargets(controller),
        ],
      ),
    );
  }
}
