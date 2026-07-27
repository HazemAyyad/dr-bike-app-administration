import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/utils/app_colors.dart';
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
        onPressedFilter: () {
          controller.filterAllMaintenances();
        },
        action: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
              height: 42.h,
              tabHorizontalPadding: 4.w,
              tabVerticalPadding: 8.h,
              tabHorizontalMargin: 2.w,
              fontSize: 13.sp,
              fitToWidthUpToCount: 4,
            ),
          ),
          const SliverToBoxAdapter(child: _MaintenanceDailyBoxStatus()),
          const MaintenanceDataWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 60.h)),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          controller.clearControllers();
          Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _MaintenanceDailyBoxStatus extends GetView<MaintenanceController> {
  const _MaintenanceDailyBoxStatus();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isMaintenanceDailyBoxOpen;
      final isLoading = controller.isDailyBoxLoading.value;
      final color = isOpen ? AppColors.customGreen1 : Colors.blueGrey;

      return Container(
        margin: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: color,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                isOpen
                    ? 'صندوق الصيانة اليومي مفتوح'
                    : 'صندوق الصيانة اليومي غير مفتوح',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            if (!isOpen)
              TextButton(
                onPressed:
                    isLoading ? null : controller.openMaintenanceDailySession,
                child: isLoading
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('فتح الصندوق'),
              ),
          ],
        ),
      );
    });
  }
}
