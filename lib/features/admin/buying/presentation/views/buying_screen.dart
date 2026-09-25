import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/bills_models/bills_model.dart';
import '../../data/models/return_purchases_models/return_products_model.dart';
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
        appBar: CustomAppBar(
          title: 'purchasesandReturns',
          action: false,
          actions: [
            Builder(
              builder: (topBarContext) {
                final tabs = DefaultTabController.of(topBarContext);
                return AnimatedBuilder(
                  animation: tabs,
                  builder: (_, __) => _BuyingSearchAction(
                    activeTab: tabs.index,
                  ),
                );
              },
            ),
            SizedBox(width: 6.w),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 2.h),
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

class _BuyingSearchAction extends StatelessWidget {
  const _BuyingSearchAction({required this.activeTab});

  final int activeTab;

  @override
  Widget build(BuildContext context) {
    if (activeTab == 1) {
      return GetBuilder<PurchaseOrdersController>(
        builder: (controller) => _button(
          visible: controller.isSearchVisible.value,
          onPressed: controller.toggleSearch,
        ),
      );
    }
    if (activeTab == 2) {
      return GetBuilder<ReturnPurchasesController>(
        builder: (controller) => _button(
          visible: controller.isSearchVisible.value,
          onPressed: controller.toggleSearch,
        ),
      );
    }
    return GetBuilder<BillsController>(
      builder: (controller) => _button(
        visible: controller.isPurchaseSearchVisible.value,
        onPressed: controller.togglePurchaseSearch,
      ),
    );
  }

  Widget _button({
    required bool visible,
    required VoidCallback onPressed,
  }) =>
      IconButton(
        tooltip: 'search'.tr,
        onPressed: onPressed,
        icon: Icon(
          visible ? Icons.search_off_rounded : Icons.search_rounded,
          color: AppColors.primaryColor,
        ),
      );
}

class _BuyingPrimaryTabs extends StatelessWidget {
  const _BuyingPrimaryTabs();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (bills) => GetBuilder<PurchaseOrdersController>(
        builder: (orders) => GetBuilder<ReturnPurchasesController>(
          builder: (returns) => SizedBox(
            height: 72.h,
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.secondaryColor,
              unselectedLabelColor:
                  ThemeService.isDark.value ? Colors.white70 : Colors.black87,
              labelStyle: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w700,
              ),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: AppColors.secondaryColor,
                  width: 3.h,
                ),
                borderRadius: BorderRadius.circular(12.r),
                insets: EdgeInsets.symmetric(horizontal: 24.w),
              ),
              tabs: [
                _primaryTab(
                  'فواتير الشراء',
                  Icons.receipt_long_outlined,
                  bills.purchaseBillsCount,
                ),
                _primaryTab(
                  'الاستلام والمتابعة',
                  Icons.inventory_2_outlined,
                  orders.totalCount,
                ),
                _primaryTab(
                  'المرتجعات',
                  Icons.assignment_return_outlined,
                  returns.totalCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryTab(String label, IconData icon, int count) => Tab(
        height: 68.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withValues(alpha: .09),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondaryColor.withValues(alpha: .2),
                    ),
                  ),
                  child: Icon(icon, size: 19.sp),
                ),
                if (count > 0)
                  PositionedDirectional(
                    top: -4.h,
                    end: -7.w,
                    child: _CountBadge(count: count),
                  ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
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
        final showOperationalSections =
            controller.purchaseBillStateFilter.value == 'all';
        final sections = showOperationalSections
            ? _purchaseSections(controller.allBillsSearch)
            : const <_BuyingListSection<BillDataModel>>[];
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
              else if (showOperationalSections)
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (final section in sections) ...[
                      _OperationalSectionHeader(
                        title: section.title,
                        count: section.count,
                        color: section.color,
                        icon: section.icon,
                      ),
                      for (final entry in section.groups.entries)
                        BillsList(
                          month: entry.key,
                          bills: entry.value,
                          page: '1',
                        ),
                    ],
                  ]),
                )
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

  List<_BuyingListSection<BillDataModel>> _purchaseSections(
    Map<String, List<BillDataModel>> source,
  ) {
    const order = [
      'awaiting_receiving',
      'partially_received',
      'receiving_issues',
      'awaiting_finalization',
      'unpaid',
      'partially_paid',
      'paid',
    ];
    final groups = <String, Map<String, List<BillDataModel>>>{};
    for (final dateEntry in source.entries) {
      for (final bill in dateEntry.value) {
        final key = _purchaseSectionKey(bill);
        if (key == null) continue;
        groups
            .putIfAbsent(key, () => <String, List<BillDataModel>>{})
            .putIfAbsent(dateEntry.key, () => <BillDataModel>[])
            .add(bill);
      }
    }
    return [
      for (final key in order)
        if (groups[key]?.isNotEmpty == true)
          _BuyingListSection<BillDataModel>(
            title: _purchaseSectionLabel(key),
            color: _purchaseSectionColor(key),
            icon: _purchaseSectionIcon(key),
            groups: groups[key]!,
          ),
    ];
  }

  String? _purchaseSectionKey(BillDataModel bill) {
    final workflow = bill.workflowStatus.toLowerCase();
    final payment = bill.paymentStatus.toLowerCase();
    if (workflow == 'awaiting_receiving' ||
        bill.status.toLowerCase() == 'draft') {
      return 'awaiting_receiving';
    }
    if (bill.hasReceivingSummary) return 'receiving_issues';
    if (workflow == 'partially_received') return 'partially_received';
    if (workflow == 'awaiting_finalization' || workflow == 'received') {
      return 'awaiting_finalization';
    }
    if (payment == 'paid') return 'paid';
    if (payment == 'partially_paid' || payment == 'partial') {
      return 'partially_paid';
    }
    if (payment == 'unpaid' || payment.isEmpty) return 'unpaid';
    return null;
  }

  String _purchaseSectionLabel(String key) {
    switch (key) {
      case 'awaiting_receiving':
        return 'بانتظار الاستلام';
      case 'partially_received':
        return 'استلام جزئي';
      case 'receiving_issues':
        return 'مشاكل الاستلام';
      case 'awaiting_finalization':
        return 'بانتظار الاعتماد';
      case 'unpaid':
        return 'فواتير غير مدفوعة';
      case 'partially_paid':
        return 'فواتير مدفوعة جزئياً';
      case 'paid':
        return 'فواتير مدفوعة';
      default:
        return 'فواتير غير مدفوعة';
    }
  }

  Color _purchaseSectionColor(String key) {
    switch (key) {
      case 'awaiting_receiving':
        return Colors.orange;
      case 'partially_received':
        return Colors.deepOrange;
      case 'receiving_issues':
        return Colors.red;
      case 'awaiting_finalization':
        return Colors.indigo;
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _purchaseSectionIcon(String key) {
    switch (key) {
      case 'awaiting_receiving':
        return Icons.inventory_outlined;
      case 'partially_received':
        return Icons.hourglass_bottom_outlined;
      case 'receiving_issues':
        return Icons.report_problem_outlined;
      case 'awaiting_finalization':
        return Icons.fact_check_outlined;
      case 'paid':
        return Icons.check_circle_outline;
      case 'partially_paid':
        return Icons.payments_outlined;
      case 'unpaid':
        return Icons.money_off_outlined;
      default:
        return Icons.more_horiz_rounded;
    }
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
      );
}

class _PurchaseOrderIconTabs extends StatelessWidget {
  const _PurchaseOrderIconTabs({required this.controller});

  final PurchaseOrdersController controller;

  static const _items = [
    _StatusTabItem.named(
      label: 'الكل',
      icon: Icons.all_inbox_outlined,
      color: Colors.blueGrey,
    ),
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
      label: 'المستلمة',
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
  });

  final List<_StatusTabItem> items;
  final int selectedIndex;
  final int Function(int index) countForIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleIndices = <int>[
      for (var index = 0; index < items.length; index++)
        if (index == 0 || countForIndex(index) > 0) index,
    ];
    return SizedBox(
      height: 70.h,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 7.h, 16.w, 3.h),
        scrollDirection: Axis.horizontal,
        itemCount: visibleIndices.length,
        separatorBuilder: (_, __) => SizedBox(width: 11.w),
        itemBuilder: (_, listIndex) {
          final index = visibleIndices[listIndex];
          final item = items[index];
          final count = countForIndex(index);
          final selected = selectedIndex == index;
          final isDark = ThemeService.isDark.value;
          final foreground =
              selected ? Colors.white : (isDark ? Colors.white : item.color);
          return Tooltip(
            message: item.label,
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(24.r),
              child: SizedBox(
                width: 52.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: selected
                            ? item.color
                            : item.color.withValues(alpha: isDark ? .18 : .09),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? item.color
                              : item.color.withValues(alpha: .24),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(item.icon, size: 20.sp, color: foreground),
                          if (count > 0)
                            PositionedDirectional(
                              top: -5.h,
                              end: -6.w,
                              child: _CountBadge(count: count),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8.sp,
                        height: 1,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
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
              final source = controller.currentSearch;
              final sections = current == 0
                  ? _receivingSections(controller)
                  : const <_BuyingListSection<BillDataModel>>[];

              if (source.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }

              if (current == 0) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    for (final section in sections) ...[
                      _OperationalSectionHeader(
                        title: section.title,
                        count: section.count,
                        color: section.color,
                        icon: section.icon,
                      ),
                      for (final entry in section.groups.entries)
                        BillsList(
                          month: entry.key,
                          bills: entry.value,
                          page: section.page!,
                        ),
                    ],
                  ]),
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
                      page: current <= 1
                          ? '2'
                          : current == 3
                              ? '1'
                              : current == 2
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

  List<_BuyingListSection<BillDataModel>> _receivingSections(
    PurchaseOrdersController controller,
  ) =>
      [
        _BuyingListSection<BillDataModel>(
          title: 'قيد الاستلام',
          color: Colors.orange,
          icon: Icons.inventory_2_outlined,
          groups: controller.unprocessedSearch,
          page: '2',
        ),
        _BuyingListSection<BillDataModel>(
          title: 'فروقات الاستلام',
          color: Colors.red,
          icon: Icons.report_problem_outlined,
          groups: controller.notMatchedSearch,
          page: '3',
        ),
        _BuyingListSection<BillDataModel>(
          title: 'الفواتير المستلمة',
          color: Colors.green,
          icon: Icons.check_circle_outline,
          groups: controller.completedSearch,
          page: '1',
        ),
        _BuyingListSection<BillDataModel>(
          title: 'الأمانات',
          color: Colors.indigo,
          icon: Icons.account_balance_wallet_outlined,
          groups: controller.depositsSearch,
          page: '4',
        ),
      ].where((section) => section.count > 0).toList(growable: false);
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

              final source = controller.returnPurchasesSearch;
              final sections = controller.currentTab.value == 0
                  ? _returnSections(source)
                  : const <_BuyingListSection<ReturnProduct>>[];

              if (source.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }

              if (controller.currentTab.value == 0) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    for (final section in sections) ...[
                      _OperationalSectionHeader(
                        title: section.title,
                        count: section.count,
                        color: section.color,
                        icon: section.icon,
                      ),
                      for (final entry in section.groups.entries)
                        ReturnPurchasesList(
                          month: entry.key,
                          bills: entry.value,
                        ),
                    ],
                  ]),
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

  List<_BuyingListSection<ReturnProduct>> _returnSections(
    Map<String, List<ReturnProduct>> source,
  ) {
    const definitions = <_ReturnSectionDefinition>[
      _ReturnSectionDefinition(
        status: 'draft',
        title: 'مسودات المرتجعات',
        color: Colors.blueGrey,
        icon: Icons.edit_note_outlined,
      ),
      _ReturnSectionDefinition(
        status: 'confirmed',
        title: 'مرتجعات قيد التسليم',
        color: Colors.orange,
        icon: Icons.local_shipping_outlined,
      ),
      _ReturnSectionDefinition(
        status: 'delivered',
        title: 'مرتجعات قيد التسوية',
        color: Colors.indigo,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _ReturnSectionDefinition(
        status: 'settled',
        title: 'المرتجعات المكتملة',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      ),
      _ReturnSectionDefinition(
        status: 'cancelled',
        title: 'المرتجعات الملغاة',
        color: Colors.red,
        icon: Icons.cancel_outlined,
      ),
    ];
    final sections = <_BuyingListSection<ReturnProduct>>[];
    for (final definition in definitions) {
      final grouped = <String, List<ReturnProduct>>{};
      for (final entry in source.entries) {
        final rows = entry.value.where((row) {
          if (definition.status == 'confirmed') {
            return row.status == 'confirmed' || row.status == 'pending';
          }
          return row.status == definition.status;
        }).toList();
        if (rows.isNotEmpty) grouped[entry.key] = rows;
      }
      if (grouped.isNotEmpty) {
        sections.add(
          _BuyingListSection<ReturnProduct>(
            title: definition.title,
            color: definition.color,
            icon: definition.icon,
            groups: grouped,
          ),
        );
      }
    }
    return sections;
  }
}

class _PurchaseReturnIconTabs extends StatelessWidget {
  const _PurchaseReturnIconTabs({required this.controller});

  final ReturnPurchasesController controller;

  static const _items = [
    _StatusTabItem.named(
        label: 'الكل', icon: Icons.all_inbox_outlined, color: Colors.blueGrey),
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
      );
    });
  }
}

class _ReturnSectionDefinition {
  const _ReturnSectionDefinition({
    required this.status,
    required this.title,
    required this.color,
    required this.icon,
  });

  final String status;
  final String title;
  final Color color;
  final IconData icon;
}

class _BuyingListSection<T> {
  const _BuyingListSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.groups,
    this.page,
  });

  final String title;
  final Color color;
  final IconData icon;
  final Map<String, List<T>> groups;
  final String? page;

  int get count => groups.values.fold<int>(
        0,
        (total, rows) => total + rows.length,
      );
}

class _OperationalSectionHeader extends StatelessWidget {
  const _OperationalSectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.w, 14.h, 16.w, 5.h),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 21.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(icon, size: 18.sp, color: color),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
}
