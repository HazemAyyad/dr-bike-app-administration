import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../controllers/purchase_orders_controller.dart';
import '../../widgets/bills_widgets/bills_list.dart';

class PurchaseOrdersScreen extends GetView<PurchaseOrdersController> {
  const PurchaseOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'purchaseOrders', action: false),
      body: AppPullToRefresh(
        onRefresh: controller.getBills,
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
            const SliverToBoxAdapter(child: PurchaseBillsTableHeader()),
            GetBuilder<PurchaseOrdersController>(
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (controller.currentTab.value == 0 &&
                    controller.unprocessedSearch.isEmpty) {
                  return const SliverFillRemaining(
                      child: Center(child: ShowNoData()));
                }
                if (controller.currentTab.value == 1 &&
                    controller.notMatchedSearch.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: ShowNoData()),
                  );
                }
                if (controller.currentTab.value == 2 &&
                    controller.completedSearch.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: ShowNoData()),
                  );
                }
                if (controller.currentTab.value == 3 &&
                    controller.depositsSearch.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: ShowNoData()),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, section) {
                      final month = controller.currentTab.value == 0
                          ? controller.unprocessedSearch.keys.toList()[section]
                          : controller.currentTab.value == 1
                              ? controller.notMatchedSearch.keys
                                  .toList()[section]
                              : controller.currentTab.value == 2
                                  ? controller.completedSearch.keys
                                      .toList()[section]
                                  : controller.depositsSearch.keys
                                      .toList()[section];
                      final bills = controller.currentTab.value == 0
                          ? controller.unprocessedSearch[month]!
                          : controller.currentTab.value == 1
                              ? controller.notMatchedSearch[month]!
                              : controller.currentTab.value == 2
                                  ? controller.completedSearch[month]!
                                  : controller.depositsSearch[month]!;

                      return BillsList(
                        month: month,
                        bills: bills,
                        page: controller.currentTab.value == 0
                            ? '2'
                            : controller.currentTab.value == 2
                                ? '1'
                                : controller.currentTab.value == 1
                                    ? '3'
                                    : '4',
                      );
                    },
                    childCount: controller.currentTab.value == 0
                        ? controller.unprocessedSearch.length
                        : controller.currentTab.value == 1
                            ? controller.notMatchedSearch.length
                            : controller.currentTab.value == 2
                                ? controller.completedSearch.length
                                : controller.depositsSearch.length,
                  ),
                );
              },
            ),
            SliverToBoxAdapter(child: SizedBox(height: 50.h)),
          ],
        ),
      ),
    );
  }
}
