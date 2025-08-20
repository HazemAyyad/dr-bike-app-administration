import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/initial_bindings.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/action_buttons.dart';
import '../../../../../../core/helpers/custom_floating_action_button.dart';
import '../widgets/employee_home_statistics_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/admin_statistics_cards.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '${'welcomeBack.'.tr} Mohamed',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(),
            SizedBox(height: 20.h),
            // بطاقات الإحصائيات
            test == 'admin'
                ? BuildStatisticsCards()
                : EmployeeHomeStatisticsCard(),
            SizedBox(height: 20.h),
            // أزرار الوظائف
            BuildActionButtons(controller: controller),
            SizedBox(height: 80.h),
          ],
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () => controller.toggleAddMenu(),
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        addList: controller.addList,
      ),
    );
  }
}
