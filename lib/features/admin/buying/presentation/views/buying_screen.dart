import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../routes/app_routes.dart';
import '../binding/buying_binding.dart';
import '../controllers/bills_controller.dart';
import '../controllers/purchase_orders_controller.dart';
import '../controllers/return_purchases_controller.dart';
import '../widgets/buying_skeleton_widgets.dart';
import '../widgets/bills_widgets/bills_list.dart';
import '../widgets/return_purchases_widgets/return_purchases_list.dart';

class BuyingScreen extends GetView<BillsController> {
  const BuyingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BillsController>()) {
      BuyingBinding().dependencies();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'purchasesandReturns',
          action: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
              child: const _BuyingPrimaryTabs(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PurchaseInvoicesTab(),
                  const _PurchaseOrdersEntryTab(),
                  const _ReturnPurchasesEntryTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة'),
          onPressed: () => _showPurchaseCreateActions(context),
        ),
      ),
    );
  }

  void _showPurchaseCreateActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة عملية شراء',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                      ),
                ),
                SizedBox(height: 10.h),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.add_shopping_cart_outlined,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: const Text('إنشاء فاتورة شراء جديدة'),
                  subtitle: const Text('اختيار مورد أو زبون ثم إضافة المنتجات'),
                  trailing: const Icon(
                    Icons.chevron_left,
                    color: AppColors.primaryColor,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.prepareNewPurchaseForm();
                    Get.toNamed(AppRoutes.ADDNEWBILLSCREEN);
                  },
                ),
                SizedBox(height: 10.h),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.secondaryColor.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.assignment_return_outlined,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  title: const Text('إنشاء مرتجع شراء'),
                  subtitle: const Text('اختيار فاتورة شراء وإرجاع منتجات منها'),
                  trailing: const Icon(
                    Icons.chevron_left,
                    color: AppColors.secondaryColor,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.toNamed(AppRoutes.CREATEPURCHASERETURNSCREEN);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BuyingPrimaryTabs extends StatelessWidget {
  const _BuyingPrimaryTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.secondaryColor,
        unselectedLabelColor: Colors.black87,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        tabs: const [
          Tab(text: 'فواتير الشراء'),
          Tab(text: 'طلبات الشراء'),
          Tab(text: 'الراجع'),
        ],
      ),
    );
  }
}

class _PurchaseInvoicesTab extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return AppPullToRefresh(
            onRefresh: controller.getBills,
            child: ListView(
              physics: kRefreshableScrollPhysics,
              children: const [BuyingBillsTableSkeleton()],
            ),
          );
        }
        if (controller.allBillsSearch.isEmpty) {
          return AppPullToRefresh(
            onRefresh: controller.getBills,
            child: ListView(
              physics: kRefreshableScrollPhysics,
              padding: EdgeInsets.fromLTRB(16.w, 80.h, 16.w, 24.h),
              children: const [ShowNoData()],
            ),
          );
        }
        final months = controller.allBillsSearch.keys.toList();
        return AppPullToRefresh(
          onRefresh: controller.getBills,
          child: ListView.builder(
            physics: kRefreshableScrollPhysics,
            padding: EdgeInsets.only(bottom: 90.h),
            itemCount: months.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return const PurchaseBillsTableHeader();
              final monthIndex = index - 1;
              final month = months[monthIndex];
              final bills = controller.allBillsSearch[month] ?? [];
              return BillsList(month: month, bills: bills, page: '1');
            },
          ),
        );
      },
    );
  }
}

class _PurchaseOrderIconTabs extends StatelessWidget {
  const _PurchaseOrderIconTabs({required this.controller});

  final PurchaseOrdersController controller;

  static const _items = [
    _PurchaseOrderTabUi(
      label: 'قيد الاستلام',
      icon: Icons.inventory_2_outlined,
      color: Colors.orange,
    ),
    _PurchaseOrderTabUi(
      label: 'فروقات',
      icon: Icons.report_problem_outlined,
      color: Colors.red,
    ),
    _PurchaseOrderTabUi(
      label: 'مكتملة',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    ),
    _PurchaseOrderTabUi(
      label: 'أمانات',
      icon: Icons.account_balance_wallet_outlined,
      color: Colors.indigo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseOrdersController>(
      builder: (_) {
        final selected = controller.currentTab.value;
        return Container(
          margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _PurchaseOrderIconTab(
                    item: _items[i],
                    selected: selected == i,
                    onTap: () => controller.changeTab(i),
                  ),
                ),
              SizedBox(width: 6.w),
              IconButton(
                tooltip: 'search'.tr,
                visualDensity: VisualDensity.compact,
                onPressed: controller.toggleSearch,
                icon: Obx(
                  () => Icon(
                    controller.isSearchVisible.value
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    color: AppColors.secondaryColor,
                    size: 22.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseOrderIconTab extends StatelessWidget {
  const _PurchaseOrderIconTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _PurchaseOrderTabUi item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : item.color;
    return Tooltip(
      message: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(9.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42.h,
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: selected ? item.color : item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: item.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: fg, size: 18.sp),
              if (selected) ...[
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseOrderTabUi {
  const _PurchaseOrderTabUi({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _PurchaseOrdersEntryTab extends GetView<PurchaseOrdersController> {
  const _PurchaseOrdersEntryTab();

  @override
  Widget build(BuildContext context) {
    return AppPullToRefresh(
      onRefresh: controller.getBills,
      child: CustomScrollView(
        physics: kRefreshableScrollPhysics,
        slivers: [
          SliverToBoxAdapter(
            child: _PurchaseOrderIconTabs(controller: controller),
          ),
          GetBuilder<PurchaseOrdersController>(
            id: 'purchaseOrdersSearchBar',
            builder: (_) => SliverToBoxAdapter(
              child: Obx(
                () => controller.isSearchVisible.value
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 6.h,
                        ),
                        child: SearchBar(
                          controller: controller.searchController,
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
                          hintText: 'ابحث برقم الفاتورة أو الطرف',
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
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          const SliverToBoxAdapter(child: PurchaseBillsTableHeader()),
          GetBuilder<PurchaseOrdersController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: BuyingBillsTableSkeleton(),
                );
              }

              final current = controller.currentTab.value;
              final source = current == 0
                  ? controller.unprocessedSearch
                  : current == 1
                      ? controller.notMatchedSearch
                      : current == 2
                          ? controller.completedSearch
                          : controller.depositsSearch;

              if (source.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }

              final months = source.keys.toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, section) {
                    final month = months[section];
                    final bills = source[month]!;
                    return BillsList(
                      month: month,
                      bills: bills,
                      page: current == 0
                          ? '2'
                          : current == 2
                              ? '1'
                              : current == 1
                                  ? '3'
                                  : '4',
                    );
                  },
                  childCount: months.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 90.h)),
        ],
      ),
    );
  }
}

class _ReturnPurchasesEntryTab extends GetView<ReturnPurchasesController> {
  const _ReturnPurchasesEntryTab();

  @override
  Widget build(BuildContext context) {
    return AppPullToRefresh(
      onRefresh: controller.getReturnBills,
      child: CustomScrollView(
        physics: kRefreshableScrollPhysics,
        slivers: [
          SliverToBoxAdapter(
            child: _PurchaseReturnIconTabs(controller: controller),
          ),
          GetBuilder<ReturnPurchasesController>(
            id: 'purchaseReturnsSearchBar',
            builder: (_) => SliverToBoxAdapter(
              child: Obx(
                () => controller.isSearchVisible.value
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 6.h,
                        ),
                        child: SearchBar(
                          controller: controller.searchController,
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
                          hintText: 'ابحث برقم المرتجع أو الفاتورة أو الطرف',
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
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          const SliverToBoxAdapter(child: PurchaseReturnsTableHeader()),
          GetBuilder<ReturnPurchasesController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: BuyingReturnListSkeleton(),
                );
              }

              final source = controller.currentTab.value == 0
                  ? controller.returnPurchasesSearch
                  : controller.deliveredPurchasesSearch;

              if (source.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }

              final months = source.keys.toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, section) {
                    final month = months[section];
                    final bills = source[month]!;
                    return ReturnPurchasesList(month: month, bills: bills);
                  },
                  childCount: months.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 90.h)),
        ],
      ),
    );
  }
}

class _PurchaseReturnIconTabs extends StatelessWidget {
  const _PurchaseReturnIconTabs({required this.controller});

  final ReturnPurchasesController controller;

  static const _items = [
    _PurchaseOrderTabUi(
        label: 'مسودات',
        icon: Icons.edit_note_outlined,
        color: Colors.blueGrey),
    _PurchaseOrderTabUi(
        label: 'قيد التسليم',
        icon: Icons.local_shipping_outlined,
        color: Colors.orange),
    _PurchaseOrderTabUi(
        label: 'قيد التسوية',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.indigo),
    _PurchaseOrderTabUi(
        label: 'مكتملة', icon: Icons.check_circle_outline, color: Colors.green),
    _PurchaseOrderTabUi(
        label: 'ملغاة', icon: Icons.cancel_outlined, color: Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReturnPurchasesController>(builder: (_) {
      final selected = controller.currentTab.value;
      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _PurchaseOrderIconTab(
                item: _items[i],
                selected: selected == i,
                onTap: () => controller.changeTab(i),
              ),
            ),
          SizedBox(width: 6.w),
          IconButton(
            tooltip: 'search'.tr,
            visualDensity: VisualDensity.compact,
            onPressed: controller.toggleSearch,
            icon: Obx(() => Icon(
                  controller.isSearchVisible.value
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
                  color: AppColors.secondaryColor,
                  size: 22.sp,
                )),
          ),
        ]),
      );
    });
  }
}
