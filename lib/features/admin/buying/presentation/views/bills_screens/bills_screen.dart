import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/bills_controller.dart';
import '../../widgets/bills_widgets/bills_list.dart';

class BillsScreen extends GetView<BillsController> {
  const BillsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'newBill',
        action: false,
      ),
      body: CustomScrollView(
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
          GetBuilder<BillsController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.currentTab.value == 0 &&
                  controller.allBillsSearch.isEmpty) {
                return const SliverFillRemaining(
                    child: Center(child: ShowNoData()));
              }
              if (controller.currentTab.value == 1 &&
                  controller.allBillsArchiveSearch.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, section) {
                    final month = controller.currentTab.value == 0
                        ? controller.allBillsSearch.keys
                            .toList()
                            .reversed
                            .toList()[section]
                        : controller.allBillsArchiveSearch.keys
                            .toList()
                            .reversed
                            .toList()[section];
                    final bills = controller.currentTab.value == 0
                        ? controller.allBillsSearch[month]
                        : controller.allBillsArchiveSearch[month];

                    return BillsList(month: month, bills: bills!, page: '1');
                  },
                  childCount: controller.currentTab.value == 0
                      ? controller.allBillsSearch.length
                      : controller.allBillsArchiveSearch.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () => controller.toggleAddMenu(),
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        // addList: controller.addList,
        customWidget: Column(
          children: [
            BuildAddMenuItem(
              title: 'addNewBill',
              iconAsset: AssetsManager.invoiceIcon,
              route: AppRoutes.ADDNEWBILLSCREEN,
              onTap: () {
                controller.isaddNewBill = '1';
                controller.toggleAddMenu();
              },
            ),
            SizedBox(height: 10.h),
            BuildAddMenuItem(
              title: 'addNewQuantityBill',
              iconAsset: AssetsManager.invoiceIcon,
              route: AppRoutes.ADDNEWBILLSCREEN,
              onTap: () {
                controller.isaddNewBill = '2';
                controller.toggleAddMenu();
              },
            ),
          ],
        ),
      ),
    );
  }
}
