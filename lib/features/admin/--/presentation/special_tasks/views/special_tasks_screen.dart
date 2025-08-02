import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/services/theme_service.dart' show ThemeService;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../my_orders/widgets/row_text.dart';
import '../controllers/special_tasks_controller.dart';
import '../widgets/order_cards.dart';

class SpecialTasksScreen extends GetView<SpecialTasksController> {
  const SpecialTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        title: 'privateTasks',
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedAdd: () {
          // Handle add button press
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: {'title': 'addNewPravateTask'},
          );
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
              width: 300.w,
            ),
            SizedBox(height: 20.h),
            Container(
              height: 32.h,
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.secondaryColor
                    : AppColors.primaryColor,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(),
                  rowText(context, 'employeeTaskName'),
                  SizedBox(),
                  rowText(context, 'employeeStartDate'),
                  Row(
                    children: [
                      rowText(context, 'employeeEndDate'),
                      Obx(
                        () => controller.currentTab.value == 1
                            ? SizedBox(width: 80.w)
                            : SizedBox(),
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 10.h),
            // Order cards
            orderCards(controller),
          ],
        ),
      ),
    );
  }
}
