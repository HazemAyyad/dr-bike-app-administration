import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/follow_up_controller.dart';
import '../widgets/follow_up_widget.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class CurrentFollowUpScreen extends GetView<FollowUpController> {
  const CurrentFollowUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'followUpDepartment',
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        employeeNameController: controller.employeeNameController,
        onPressedFilter: () => controller.filterGoals(),
        label: 'customerName',
        action: false,
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
            // tab bar
            SliverToBoxAdapter(
              child: GetBuilder<FollowUpController>(
                builder: (controller) {
                  return AppTabs(
                    tabs: [
                      '${'initialFollowUp'.tr} (${controller.initialCount})',
                      '${'notify_customer'.tr} (${controller.informCount})',
                      '${'completion_and_agreement'.tr} (${controller.finishAgreementCount})',
                      '${'archive'.tr} (${controller.archivedCount})',
                    ],
                    currentTab: controller.currentTab,
                    changeTab: controller.changeTab,
                    translateLabels: false,
                    height: 34.h,
                    horizontalPadding: 2.w,
                    tabHorizontalMargin: 1.w,
                    tabHorizontalPadding: 8.w,
                    tabVerticalPadding: 5.h,
                    fontSize: 10.5.sp,
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: SearchBar(
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  leading: const Icon(
                    Icons.search,
                  ),
                  hintText: 'search'.tr,
                  backgroundColor: WidgetStateProperty.all(
                    ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor7,
                  ),
                  onChanged: (value) => controller.searchBar(value),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: GetBuilder<FollowUpController>(
                  builder: (c) => Text(
                    '${'total'.tr}: ${c.activeFilteredCount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeService.isDark.value
                              ? Colors.white
                              : AppColors.secondaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            const FollowUpWidget(),
            SliverToBoxAdapter(child: SizedBox(height: 30.h)),
          ],
        ),
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          controller.resetData();
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
