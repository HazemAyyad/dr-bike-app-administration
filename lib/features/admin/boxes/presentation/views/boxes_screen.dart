import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/boxes_controller.dart';
import '../widgets/view_boxes.dart';

class BoxesScreen extends GetView<BoxesController> {
  const BoxesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'boxes',
        employeeNameController: controller.boxNameController,
        // fromDateController: controller.fromDateController,
        // toDateController: controller.toDateController,
        label: 'boxName',
        onPressedFilter: () => controller.filterLists(),
        onPressedAdd: () {
          Get.toNamed(AppRoutes.CREATEBOXESSCREEN);
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80.h,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  SizedBox(height: 10.h),
                  AppTabs(
                    tabs: controller.tabs,
                    currentTab: controller.currentTab,
                    changeTab: controller.changeTab,
                    width: 350.w,
                  ),
                ],
              ),
            ),
          ),
          VeiwBoxes(),
        ],
      ),
    );
  }
}
