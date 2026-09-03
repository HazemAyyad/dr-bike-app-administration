import 'dart:ui';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/widgets/open_desktop_window_button.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/instant_sales_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';
import '../widgets/profit_sale_card.dart';
import '../widgets/sales_invoices_toolbar.dart';
import '../widgets/sales_skeleton_widgets.dart';
import '../../../sales_orders/presentation/controllers/sales_orders_controller.dart';
import '../../../sales_orders/presentation/widgets/sales_orders_table.dart';
import '../../../sales_orders/presentation/widgets/sales_orders_toolbar.dart';
import '../../../sales_returns/presentation/controllers/sales_returns_controller.dart';
import '../../../sales_returns/presentation/widgets/sales_returns_list.dart';

class SalesScreen extends GetView<SalesController> {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'sales',
        action: false,
        actions: [
          _SalesAppBarTabs(controller: controller),
          Obx(
            () => _SmallSalesAction(
              tooltip: 'search'.tr,
              onTap: controller.toggleSalesSearch,
              icon: controller.isSalesSearchVisible.value
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 700)
            const OpenDesktopWindowButton(
              route: AppRoutes.SALESSCREEN,
              title: 'sales',
            ),
          _SalesDailyBoxButton(controller: controller),
          _SalesTopActions(controller: controller),
          SizedBox(width: 4.w),
        ],
      ),
      body: Stack(
        children: [
          AppPullToRefresh(
            onRefresh: () async {
              if (controller.currentTab.value == 3) {
                await Get.find<SalesReturnsController>().loadReturns();
                return;
              }
              if (controller.currentTab.value == 2) {
                if (Get.isRegistered<SalesOrdersController>()) {
                  await Get.find<SalesOrdersController>().loadOrders();
                }
                return;
              }
              await controller.refreshSales();
            },
            child: CustomScrollView(
              physics: kRefreshableScrollPhysics,
              slivers: [
                const SliverToBoxAdapter(child: _SalesSearchBar()),
                Obx(
                  () {
                    if (controller.currentTab.value == 2) {
                      return const SliverToBoxAdapter(
                        child: SalesOrdersToolbar(),
                      );
                    }
                    if (controller.currentTab.value == 0) {
                      return const SliverToBoxAdapter(
                        child: SalesInvoicesToolbar(),
                      );
                    }
                    return const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  },
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: Obx(
                    () {
                      final tab = controller.currentTab.value;
                      if (tab == 2) {
                        if (Get.isRegistered<SalesOrdersController>()) {
                          final ordersCtrl = Get.find<SalesOrdersController>();
                          final ordersLoading = ordersCtrl.isLoading.value;
                          final orderCount = ordersCtrl.orders.length;
                          if (ordersLoading && orderCount == 0) {
                            return const SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (orderCount == 0) {
                            return const SliverFillRemaining(
                                child: ShowNoData());
                          }
                        }
                        return const SliverToBoxAdapter(
                          child: SalesOrdersTable(),
                        );
                      }
                      if (tab == 3) {
                        return const SliverToBoxAdapter(
                          child: SalesReturnsList(),
                        );
                      }

                      final _ = controller.salesListRevision.value;
                      if (tab == 0) {
                        controller.instantSalesPackageFilter.value;
                      }
                      final showListSkeleton = controller.isLoading.value &&
                          (tab == 0
                              ? !controller.hasInstantSalesData
                              : !controller.hasProfitSalesData);
                      if (showListSkeleton) {
                        return const SliverToBoxAdapter(
                          child: SalesInvoicesListSkeleton(),
                        );
                      }
                      if (tab == 0) {
                        if (controller
                            .orderedInstantSalesGroupsFiltered.isEmpty) {
                          return const SliverFillRemaining(child: ShowNoData());
                        }
                      } else if (tab == 1) {
                        if (controller
                            .salesService.filterProfitSalesTasks.isEmpty) {
                          return const SliverFillRemaining(child: ShowNoData());
                        }
                      }
                      return SliverToBoxAdapter(
                        child: tab == 0
                            ? const InstantSalesTable()
                            : const ProfitSalesTable(),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 50.h)),
              ],
            ),
          ),
          Obx(
            () {
              if (!controller.isAddMenuOpen.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  onTap: controller.toggleAddMenu,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () => controller.toggleAddMenu(),
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        addList: controller.addList,
        beforeNavigate: controller.prepareCreateNavigation,
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _SalesAppBarTabs extends StatelessWidget {
  const _SalesAppBarTabs({required this.controller});

  final SalesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.salesListRevision.value;
      final ordersController = Get.isRegistered<SalesOrdersController>()
          ? Get.find<SalesOrdersController>()
          : null;
      final returnsController = Get.find<SalesReturnsController>();
      final items = [
        _SalesSectionTabData(
          label: 'spotSale'.tr,
          icon: Icons.point_of_sale_outlined,
          count: controller.visibleInstantSalesCount,
        ),
        _SalesSectionTabData(
          label: 'cashProfit'.tr,
          icon: Icons.trending_up_rounded,
          count: controller.visibleProfitSalesCount,
        ),
        _SalesSectionTabData(
          label: 'salesOrders'.tr,
          icon: Icons.local_shipping_outlined,
          count: ordersController?.totalOrdersCount ?? 0,
        ),
        _SalesSectionTabData(
          label: 'مرتجعات المبيعات',
          icon: Icons.assignment_return_outlined,
          count: returnsController.returns.length,
          color: salesReturnColor,
        ),
      ];

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = controller.currentTab.value == index;
          final color = item.color ?? AppColors.secondaryColor;
          return Tooltip(
            message: item.label,
            child: IconButton(
              constraints: BoxConstraints.tightFor(width: 36.w, height: 38.h),
              padding: EdgeInsets.all(1.w),
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.changeTab(index),
              icon: Badge(
                isLabelVisible: item.count > 0,
                label: Text(item.count > 99 ? '99+' : '${item.count}'),
                child: Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 19.sp,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }
}

class _SalesSearchBar extends GetView<SalesController> {
  const _SalesSearchBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isSalesSearchVisible.value) {
        return const SizedBox.shrink();
      }
      final tab = controller.currentTab.value;
      if (tab == 3) {
        final returnsController = Get.find<SalesReturnsController>();
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: SearchBar(
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            leading: const Icon(Icons.search),
            trailing: [
              IconButton(
                tooltip: 'cancel'.tr,
                onPressed: () {
                  returnsController.returnsSearch.value = '';
                  controller.closeSalesSearch();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
            hintText: 'ابحث برقم المرتجع أو اسم الطرف أو الهاتف',
            backgroundColor:
                WidgetStateProperty.all(AppColors.customGreyColor7),
            onChanged: (value) => returnsController.returnsSearch.value = value,
          ),
        );
      }
      if (tab == 2) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: const _SalesOrdersSearchBar(),
        );
      }
      final textController = tab == 0
          ? controller.instantSalesSearchController
          : controller.profitSalesSearchController;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: SearchBar(
          controller: textController,
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          leading: const Icon(Icons.search),
          trailing: [
            IconButton(
              tooltip: 'cancel'.tr,
              onPressed: controller.closeSalesSearch,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
          hintText: tab == 0 ? 'searchInvoicesHint'.tr : 'بحث في البيع الربحي',
          backgroundColor: WidgetStateProperty.all(
            AppColors.customGreyColor7,
          ),
          onChanged: tab == 0
              ? controller.onInstantSalesSearchChanged
              : controller.onProfitSalesSearchChanged,
        ),
      );
    });
  }
}

class _SalesOrdersSearchBar extends GetView<SalesOrdersController> {
  const _SalesOrdersSearchBar();

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller.searchController,
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      leading: const Icon(Icons.search),
      trailing: [
        IconButton(
          tooltip: 'cancel'.tr,
          onPressed: Get.find<SalesController>().closeSalesSearch,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
      hintText: 'البحث برقم الطلبية أو اسم الزبون أو الهاتف',
      backgroundColor: WidgetStateProperty.all(AppColors.customGreyColor7),
      onChanged: controller.onSearchChanged,
    );
  }
}

class _SalesSectionTabData {
  const _SalesSectionTabData({
    required this.label,
    required this.icon,
    required this.count,
    this.color,
  });

  final String label;
  final IconData icon;
  final int count;
  final Color? color;
}

class _SalesTopActions extends StatelessWidget {
  const _SalesTopActions({required this.controller});

  final SalesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final suspended = controller.suspendedInvoicesCount.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.currentTab.value < 2)
            _SmallSalesAction(
              tooltip: (controller.currentTab.value == 0
                      ? controller.instantSalesSortDescending.value
                      : controller.profitSalesSortDescending.value)
                  ? 'sortNewestFirst'.tr
                  : 'sortOldestFirst'.tr,
              icon: (controller.currentTab.value == 0
                      ? controller.instantSalesSortDescending.value
                      : controller.profitSalesSortDescending.value)
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              onTap: controller.currentTab.value == 0
                  ? controller.toggleInstantSalesSort
                  : controller.toggleProfitSalesSort,
            ),
          if (canManageSalesSettings || canManageDeliveryCompanyAccounts)
            _SmallSalesAction(
              tooltip: 'إعدادات المبيعات',
              icon: Icons.settings_outlined,
              onTap: () => Get.toNamed(AppRoutes.SALESSETTINGSSCREEN),
            ),
          _SmallSalesAction(
            tooltip: 'suspendedInvoices'.tr,
            icon: Icons.pause_circle_outline,
            badge: suspended,
            onTap: () async {
              await Get.toNamed(AppRoutes.SUSPENDEDINVOICESSCREEN);
              await controller.loadSuspendedInvoicesCount();
            },
          ),
        ],
      );
    });
  }
}

class _SmallSalesAction extends StatelessWidget {
  const _SmallSalesAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        constraints: BoxConstraints.tightFor(width: 34.w, height: 38.h),
        padding: EdgeInsets.all(3.w),
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Badge(
          isLabelVisible: badge > 0,
          label: Text(badge > 99 ? '99+' : '$badge'),
          child: Icon(icon, size: 19.sp, color: AppColors.secondaryColor),
        ),
      ),
    );
  }
}

class _SalesDailyBoxButton extends StatelessWidget {
  const _SalesDailyBoxButton({required this.controller});

  final SalesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = controller.currentTab.value == 2;
      final payload = orders
          ? controller.salesOrdersDailySessionPayload.value
          : controller.dailySessionPayload.value;
      final rows =
          orders ? payload?.salesOrdersCurrencies : payload?.currencies;
      final shekel = rows?.firstWhereOrNull((row) => row.currency == 'شيكل');
      final balance = shekel?.systemBalance ?? 0;
      final closingRequests = controller.pendingDailyClosingCount.value;
      final loading = controller.isDailySessionLoading.value;
      final closing = payload?.isClosingRequested ?? false;
      final open = payload?.allowsSales ?? false;
      final color = loading
          ? Colors.grey
          : closing
              ? Colors.orange
              : open
                  ? Colors.green
                  : Colors.redAccent;
      final status = loading
          ? 'جارٍ تحميل حالة الصندوق'
          : closing
              ? 'بانتظار إغلاق الصندوق'
              : open
                  ? 'الصندوق اليومي مفتوح'
                  : 'الصندوق اليومي مغلق';

      return Tooltip(
        message:
            '${orders ? 'صندوق الطلبيات اليومي' : 'صندوق المبيعات اليومي'} — $status — ${balance.toStringAsFixed(0)} ₪',
        child: IconButton(
          constraints: BoxConstraints.tightFor(width: 38.w, height: 40.h),
          padding: EdgeInsets.all(2.w),
          visualDensity: VisualDensity.compact,
          onPressed: () => Get.toNamed(
            AppRoutes.SALESDAILYHISTORYSCREEN,
            arguments: {
              'sessionType': orders ? 'sales_orders' : 'instant_sales',
            },
          ),
          icon: Badge(
            isLabelVisible: closingRequests > 0,
            label: Text(
              closingRequests > 99 ? '99+' : '$closingRequests',
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                orders
                    ? Icons.local_shipping_outlined
                    : Icons.account_balance_wallet_outlined,
                color: color,
                size: 17.sp,
              ),
            ),
          ),
        ),
      );
    });
  }
}
