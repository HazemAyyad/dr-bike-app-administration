import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../../routes/app_routes.dart';
import '../../binding/buying_binding.dart';
import '../../controllers/bills_controller.dart';
import '../../widgets/bills_widgets/bills_list.dart';

class BillsScreen extends GetView<BillsController> {
  const BillsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BillsController>()) {
      BuyingBinding().dependencies();
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: 'فواتير الشراء',
        action: false,
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'search'.tr,
              onPressed: controller.togglePurchaseSearch,
              icon: Icon(
                controller.isPurchaseSearchVisible.value
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: controller.getBills,
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Center(
                  child: GetBuilder<BillsController>(
                    builder: (controller) => AppTabs(
                      tabs: controller.tabs,
                      currentTab: controller.currentTab,
                      changeTab: controller.changeTab,
                    ),
                  ),
                ),
              ),
            ),
            GetBuilder<BillsController>(
              id: 'purchaseSearchBar',
              builder: (_) => SliverToBoxAdapter(
                child: Obx(
                  () => controller.isPurchaseSearchVisible.value
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          child: SearchBar(
                            controller: controller.searchController,
                            shadowColor:
                                WidgetStateProperty.all(Colors.transparent),
                            leading: const Icon(Icons.search),
                            trailing: [
                              IconButton(
                                tooltip: 'cancel'.tr,
                                onPressed: controller.closePurchaseSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                            hintText: 'ابحث برقم الفاتورة أو المصدر',
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
            const SliverToBoxAdapter(child: _PurchaseBillStateFilters()),
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),
            const SliverToBoxAdapter(child: PurchaseBillsTableHeader()),
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
                          ? controller.allBillsSearch.keys.toList()[section]
                          : controller.allBillsArchiveSearch.keys
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: Text('addNewBill'.tr),
        onPressed: () {
          controller.isaddNewBill = '1';
          Get.toNamed(AppRoutes.ADDNEWBILLSCREEN);
        },
      ),
    );
  }
}

class _PurchaseBillStateFilters extends GetView<BillsController> {
  const _PurchaseBillStateFilters();

  static const _states = [
    _PurchaseBillState('all', 'الكل', Icons.all_inbox_outlined),
    _PurchaseBillState(
      'awaiting_receiving',
      'بانتظار الاستلام',
      Icons.inventory_outlined,
    ),
    _PurchaseBillState(
      'partially_received',
      'استلام جزئي',
      Icons.hourglass_bottom_outlined,
    ),
    _PurchaseBillState(
      'receiving_issues',
      'مشاكل استلام',
      Icons.report_problem_outlined,
    ),
    _PurchaseBillState(
      'awaiting_finalization',
      'بانتظار الاعتماد',
      Icons.fact_check_outlined,
    ),
    _PurchaseBillState('unpaid', 'غير مدفوعة', Icons.money_off_outlined),
    _PurchaseBillState(
        'partially_paid', 'مدفوعة جزئياً', Icons.payments_outlined),
    _PurchaseBillState('paid', 'مدفوعة', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        final selectedState = controller.purchaseBillStateFilter.value;
        return SizedBox(
          height: 44.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: _states.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, index) {
              final state = _states[index];
              final selected = selectedState == state.value;
              return ChoiceChip(
                selected: selected,
                avatar: Icon(
                  state.icon,
                  size: 15.sp,
                  color: selected ? Colors.white : AppColors.primaryColor,
                ),
                label: Text(state.label),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.sp,
                ),
                selectedColor: AppColors.primaryColor,
                backgroundColor: Colors.grey.shade50,
                side: BorderSide(
                  color:
                      selected ? AppColors.primaryColor : Colors.grey.shade200,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                onSelected: (_) =>
                    controller.changePurchaseBillStateFilter(state.value),
              );
            },
          ),
        );
      },
    );
  }
}

class _PurchaseBillState {
  final String value;
  final String label;
  final IconData icon;

  const _PurchaseBillState(this.value, this.label, this.icon);
}
