import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/maintenance_controller.dart';
import '../widgets/maintenance_data_widget.dart';

class MaintenanceScreen extends GetView<MaintenanceController> {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'maintenance',
        employeeNameController: controller.employeeNameController,
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedAdd: () {
          Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80.h,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Center(
                child: AppTabs(
                  tabs: controller.tabs,
                  currentTab: controller.currentTab,
                  changeTab: controller.changeTab,
                ),
              ),
            ),
          ),
          const MaintenanceDataWidget(),
        ],
      ),
    );
  }
}
