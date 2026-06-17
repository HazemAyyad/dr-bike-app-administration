import 'dart:ui';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/instant_sales_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
import '../widgets/sales_daily_status_bar.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../controllers/sales_controller.dart';
import '../widgets/profit_sale_card.dart';
import '../widgets/profit_sales_toolbar.dart';
import '../widgets/sales_invoices_toolbar.dart';
import '../widgets/sales_skeleton_widgets.dart';
import '../../../sales_orders/presentation/controllers/sales_orders_controller.dart';
import '../../../sales_orders/presentation/widgets/sales_orders_table.dart';
import '../../../sales_orders/presentation/widgets/sales_orders_toolbar.dart';

class SalesScreen extends GetView<SalesController> {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'sales',
        action: false,
        actions: [
          Obx(
            () {
              final count = controller.suspendedInvoicesCount.value;
              return IconButton(
                tooltip: 'suspendedInvoices'.tr,
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.pause_circle_outline),
                ),
                onPressed: () async {
                  await Get.toNamed(AppRoutes.SUSPENDEDINVOICESSCREEN);
                  await controller.loadSuspendedInvoicesCount();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Get.toNamed(AppRoutes.SALESDAILYHISTORYSCREEN),
          ),
          if (userType == 'admin')
            IconButton(
              icon: const Icon(Icons.pending_actions_outlined),
              onPressed: () async {
                await Get.toNamed(AppRoutes.SALESDAILYADMINSCREEN);
                await controller.loadDailySession();
              },
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => controller.filterLists(true),
          ),
          SizedBox(width: 10.w),
        ],
        onPressedFilter: () {
          controller.filterLists(true);
        },
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
      ),
      body: Stack(
        children: [
          AppPullToRefresh(
            onRefresh: () async {
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
                const SliverToBoxAdapter(
                  child: SalesDailyStatusBar(),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Center(
                        child: AppTabs(
                          tabs: controller.tabs,
                          currentTab: controller.currentTab,
                          changeTab: controller.changeTab,
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
                Obx(
                  () {
                    if (controller.currentTab.value == 2) {
                      return const SliverToBoxAdapter(
                        child: SalesOrdersToolbar(),
                      );
                    }
                    final toolbar = controller.currentTab.value == 0
                        ? const SalesInvoicesToolbar()
                        : const ProfitSalesToolbar();
                    return SliverToBoxAdapter(
                      child: Column(
                        children: [
                          toolbar,
                          SizedBox(height: 8.h),
                        ],
                      ),
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
                            return const SliverFillRemaining(child: ShowNoData());
                          }
                        }
                        return const SliverToBoxAdapter(
                          child: SalesOrdersTable(),
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
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
