import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
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
        action: false,
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'search'.tr,
              onPressed: controller.toggleSearch,
              icon: Icon(
                controller.isSearchVisible.value
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
            GetBuilder<FollowUpController>(
              id: 'searchBar',
              builder: (_) => SliverToBoxAdapter(
                child: Obx(
                  () => controller.isSearchVisible.value
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          child: SearchBar(
                            controller: controller.employeeNameController,
                            shadowColor:
                                WidgetStateProperty.all(Colors.transparent),
                            leading: const Icon(Icons.search),
                            trailing: [
                              IconButton(
                                tooltip: 'cancel'.tr,
                                onPressed: controller.closeSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                            hintText: 'search'.tr,
                            backgroundColor: WidgetStateProperty.all(
                              ThemeService.isDark.value
                                  ? AppColors.customGreyColor
                                  : AppColors.customGreyColor7,
                            ),
                            onChanged: controller.searchBar,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: GetBuilder<FollowUpController>(
                  builder: (c) => Text(
                    '${'total'.tr}: ${c.totalFilteredCount}',
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
