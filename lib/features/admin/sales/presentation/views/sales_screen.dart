import 'dart:ui';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/instant_sales_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../controllers/sales_controller.dart';
import '../widgets/profit_sale_card.dart';
import '../widgets/profit_sales_toolbar.dart';
import '../widgets/sales_invoices_toolbar.dart';

class SalesScreen extends GetView<SalesController> {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'sales',
        action: false,
        onPressedFilter: () {
          controller.filterLists(true);
        },
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
      ),
      body: Stack(
        children: [
          AppPullToRefresh(
            onRefresh: controller.refreshSales,
            child: CustomScrollView(
              physics: kRefreshableScrollPhysics,
              slivers: [
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
                      final _ = controller.salesListRevision.value;
                      if (controller.currentTab.value == 0) {
                        controller.instantSalesPackageFilter.value;
                      }
                      if (controller.isLoading.value) {
                        return const SliverFillRemaining(
                          hasScrollBody: true,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (controller.currentTab.value == 0) {
                        if (controller
                            .orderedInstantSalesGroupsFiltered.isEmpty) {
                          return const SliverFillRemaining(child: ShowNoData());
                        }
                      } else if (controller.currentTab.value == 1) {
                        if (controller
                            .salesService.filterProfitSalesTasks.isEmpty) {
                          return const SliverFillRemaining(child: ShowNoData());
                        }
                      }
                      return SliverToBoxAdapter(
                        child: controller.currentTab.value == 0
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
          // const AddList(),
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
