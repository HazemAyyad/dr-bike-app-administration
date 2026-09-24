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
    return GetBuilder<BillsController>(
      builder: (bills) => GetBuilder<PurchaseOrdersController>(
        builder: (orders) => GetBuilder<ReturnPurchasesController>(
          builder: (returns) => Container(
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
              unselectedLabelColor:
                  ThemeService.isDark.value ? Colors.white70 : Colors.black87,
              labelStyle:
                  TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w800),
              unselectedLabelStyle:
                  TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
              indicator: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor4
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6.r,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              tabs: [
                _primaryTab('فواتير الشراء', bills.purchaseBillsCount),
                _primaryTab('الاستلام والمتابعة', orders.totalCount),
                _primaryTab('المرتجعات', returns.totalCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryTab(String label, int count) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PurchaseInvoicesTab extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        final months = controller.allBillsSearch.keys.toList();
        return AppPullToRefresh(
          onRefresh: controller.getBills,
          child: CustomScrollView(
            physics: kRefreshableScrollPhysics,
            slivers: [
              const SliverToBoxAdapter(child: _PurchaseInvoiceStatusTabs()),
              SliverToBoxAdapter(
                child: Obx(
                  () => controller.isPurchaseSearchVisible.value
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 6.h),
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
              if (controller.isLoading.value)
                const SliverToBoxAdapter(child: BuyingBillsTableSkeleton())
              else if (months.isEmpty)
                const SliverFillRemaining(child: Center(child: ShowNoData()))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final month = months[index];
                      final bills = controller.allBillsSearch[month] ?? [];
                      return BillsList(month: month, bills: bills, page: '1');
                    },
                    childCount: months.length,
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 90.h)),
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseInvoiceStatusTabs extends GetView<BillsController> {
  const _PurchaseInvoiceStatusTabs();

  static const _items = [
    _StatusTabItem('الكل', Icons.all_inbox_outlined, Colors.blueGrey),
    _StatusTabItem('بانتظار الاستلام', Icons.inventory_outlined, Colors.orange),
    _StatusTabItem(
      'استلام جزئي',
      Icons.hourglass_bottom_outlined,
      Colors.deepOrange,
    ),
    _StatusTabItem(
      'مشاكل استلام',
      Icons.report_problem_outlined,
      Colors.red,
    ),
    _StatusTabItem(
      'بانتظار الاعتماد',
      Icons.fact_check_outlined,
      Colors.indigo,
    ),
    _StatusTabItem('غير مدفوعة', Icons.money_off_outlined, Colors.red),
    _StatusTabItem('مدفوعة جزئياً', Icons.payments_outlined, Colors.orange),
    _StatusTabItem('مدفوعة', Icons.check_circle_outline, Colors.green),
  ];

  static const _values = [
    'all',
    'awaiting_receiving',
    'partially_received',
    'receiving_issues',
    'awaiting_finalization',
    'unpaid',
    'partially_paid',
    'paid',
  ];

  @override
  Widget build(BuildContext context) => _OperationalStatusBar(
        items: _items,
        selectedIndex:
            _values.indexOf(controller.purchaseBillStateFilter.value),
        countForIndex: (index) =>
            controller.purchaseBillStateCount(_values[index]),
        onSelected: (index) =>
            controller.changePurchaseBillStateFilter(_values[index]),
        searchVisible: controller.isPurchaseSearchVisible.value,
        onSearch: controller.togglePurchaseSearch,
      );
}

class _PurchaseOrderIconTabs extends StatelessWidget {
  const _PurchaseOrderIconTabs({required this.controller});

  final PurchaseOrdersController controller;

  static const _items = [
    _StatusTabItem.named(
      label: 'قيد الاستلام',
      icon: Icons.inventory_2_outlined,
      color: Colors.orange,
    ),
    _StatusTabItem.named(
      label: 'فروقات',
      icon: Icons.report_problem_outlined,
      color: Colors.red,
    ),
    _StatusTabItem.named(
      label: 'مكتملة',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    ),
    _StatusTabItem.named(
      label: 'أمانات',
      icon: Icons.account_balance_wallet_outlined,
      color: Colors.indigo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseOrdersController>(
      builder: (_) => _OperationalStatusBar(
        items: _items,
        selectedIndex: controller.currentTab.value,
        countForIndex: controller.tabCount,
        onSelected: controller.changeTab,
        searchVisible: controller.isSearchVisible.value,
        onSearch: controller.toggleSearch,
      ),
    );
  }
}

class _StatusTabItem {
  const _StatusTabItem(
    this.label,
    this.icon,
    this.color,
  );

  const _StatusTabItem.named({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _OperationalStatusBar extends StatelessWidget {
  const _OperationalStatusBar({
    required this.items,
    required this.selectedIndex,
    required this.countForIndex,
    required this.onSelected,
    required this.searchVisible,
    required this.onSearch,
  });

  final List<_StatusTabItem> items;
  final int selectedIndex;
  final int Function(int index) countForIndex;
  final ValueChanged<int> onSelected;
  final bool searchVisible;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 10.w, 4.h),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = selectedIndex == index;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(end: 8.w),
                      child: FilterChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(
                          item.icon,
                          size: 15.sp,
                          color: item.color,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                color: ThemeService.isDark.value
                                    ? Colors.white
                                    : Colors.grey.shade800,
                                fontSize: 11.sp,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(99.r),
                              ),
                              child: Text(
                                '${countForIndex(index)}',
                                style: TextStyle(
                                  color: item.color,
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.whiteColor2,
                        selectedColor: item.color.withValues(alpha: 0.13),
                        side: BorderSide(
                          color: selected ? item.color : Colors.grey.shade300,
                        ),
                        onSelected: (_) => onSelected(index),
                      ),
                    );
                  }),
                ),
              ),
            ),
            IconButton(
              tooltip: 'search'.tr,
              visualDensity: VisualDensity.compact,
              onPressed: onSearch,
              icon: Icon(
                searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
                color: AppColors.secondaryColor,
                size: 22.sp,
              ),
            ),
          ],
        ),
      );
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
    _StatusTabItem.named(
        label: 'مسودات',
        icon: Icons.edit_note_outlined,
        color: Colors.blueGrey),
    _StatusTabItem.named(
        label: 'قيد التسليم',
        icon: Icons.local_shipping_outlined,
        color: Colors.orange),
    _StatusTabItem.named(
        label: 'قيد التسوية',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.indigo),
    _StatusTabItem.named(
        label: 'مكتملة', icon: Icons.check_circle_outline, color: Colors.green),
    _StatusTabItem.named(
        label: 'ملغاة', icon: Icons.cancel_outlined, color: Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReturnPurchasesController>(builder: (_) {
      return _OperationalStatusBar(
        items: _items,
        selectedIndex: controller.currentTab.value,
        countForIndex: controller.tabCount,
        onSelected: controller.changeTab,
        searchVisible: controller.isSearchVisible.value,
        onSearch: controller.toggleSearch,
      );
    });
  }
}
