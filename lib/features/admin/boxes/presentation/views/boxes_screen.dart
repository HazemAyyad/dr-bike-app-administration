import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/boxes_controller.dart';
import '../widgets/view_boxes.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class BoxesScreen extends GetView<BoxesController> {
  const BoxesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'boxes',
        employeeNameController: controller.boxNameController,
        label: 'boxName',
        onPressedFilter: () => controller.filterLists(),
        action: false,
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: SearchBar(
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16),
                ),
                hintStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16),
                ),
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
          const VeiwBoxes(),
        ],
        ),
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.CREATEBOXESSCREEN);
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
