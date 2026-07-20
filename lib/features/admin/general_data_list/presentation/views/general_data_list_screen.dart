import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';
import '../widgets/global_data.dart';

class GeneralDataListScreen extends GetView<GeneralDataListController> {
  const GeneralDataListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'generalDataList',
        // toDateController: controller.toDateController,
        // fromDateController: controller.fromDateController,
        // employeeNameController: controller.employeeNameController,
        label: 'customerName',

        action: false,
      ),
      body: AppPullToRefresh(
        onRefresh: () async => controller.getGeneralData(loding: true),
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
                child: Center(
                  child: AbsorbPointer(
                    absorbing: employeePermissions.contains(40) &&
                            !employeePermissions.contains(9)
                        ? true
                        : false,
                    child: AppTabs(
                      tabs: controller.tabs,
                      currentTab: controller.currentTab,
                      changeTab: controller.changeTab,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.darkColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'search'.tr,
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor5
                          : AppColors.customGreyColor4,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor
                          : AppColors.secondaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 12.w,
                    ),
                  ),
                  onChanged: (value) => controller.searchBar(value),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            GetBuilder<GeneralDataListController>(
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    hasScrollBody: true,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final list = controller.currentTab.value == 0
                    ? controller.employeeSearch
                    : controller.currentTab.value == 1
                        ? controller.sellersSearch
                        : controller.inCompleteDataSearch;
                if (list.isEmpty) {
                  return const SliverFillRemaining(child: ShowNoData());
                }
                final reversedList = list.reversed.toList();
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return GlobalData(employee: reversedList[index]);
                      },
                      childCount: reversedList.length,
                    ),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(child: SizedBox(height: 56.h)),
          ],
        ),
      ),
      floatingActionButton:
          employeePermissions.contains(40) && !employeePermissions.contains(9)
              ? null
              : AddFloatingActionButton(
                  onPressed: () {
                    controller.isEdit.value = false;
                    controller.clearForm();
                    // Handle add button press
                    Get.toNamed(
                      AppRoutes.ADDNEWCUSTOMERSCREEN,
                      arguments: {
                        'employeeType': '',
                        'employeeId': '',
                        'sellerId': '',
                      },
                    );
                  },
                ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
