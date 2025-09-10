import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';

import '../../../../../core/services/initial_bindings.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/actions_buttons.dart';
import '../widgets/admin_statistics_cards.dart';
import '../widgets/search_bar.dart';

class AdminDashboardScreen extends GetView<AdminDashboardController> {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          userName.isEmpty
              ? 'welcomeBack.'.tr
              : '${'welcomeBack.'.tr}  $userName',
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
            const CustomSearchBar(),
            SizedBox(height: 20.h),
            // بطاقات الإحصائيات
            const BuildStatisticsCards(),
            SizedBox(height: 20.h),
            // أزرار الوظائف
            BuildActionButtons(buttons: controller.buttons),
            SizedBox(height: 80.h),
          ],
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () => controller.toggleAddMenu(),
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        addList: controller.adminAddList,
      ),
    );
  }
}
