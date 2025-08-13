import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';
import '../widgets/global_data.dart';

class GeneralDataListScreen extends GetView<GeneralDataListController> {
  const GeneralDataListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'generalDataList',
        toDateController: controller.toDateController,
        fromDateController: controller.fromDateController,
        employeeNameController: controller.employeeNameController,
        label: 'customerName',
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(AppRoutes.ADDNEWCUSTOMERSCREEN);
        },
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            // global tab bar
            AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
              width: 270.w,
            ),
            SizedBox(height: 20.h),
            // global data
            GlobalData(controller: controller),
          ],
        ),
      ),
    );
  }
}
