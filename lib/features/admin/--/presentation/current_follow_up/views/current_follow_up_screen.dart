import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../routes/app_routes.dart';
import '../controllers/current_follow_up_controller.dart';
import '../widgets/follow_up_table_header.dart';
import '../widgets/follow_up_list.dart';

class CurrentFollowUpScreen extends GetView<CurrentFollowUpController> {
  const CurrentFollowUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'followUpDepartment',
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(AppRoutes.ADDCUSTOMERFOLLOWUPSCREEN);
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            // tab bar
            AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
              width: 300.w,
            ),
            SizedBox(height: 20.h),
            // follow up table header
            followUpTableHeader(context, controller),
            SizedBox(height: 15.h),
            // follow up list
            followUpList(controller),
          ],
        ),
      ),
    );
  }
}
