import 'dart:ui';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/instant_sale_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';
import '../widgets/add_list.dart';
import '../widgets/profit_sale_card.dart';

class SalesScreen extends GetView<SalesController> {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'sales',
        onPressedAdd: () {
          controller.toggleAddMenu();
        },
        onPressedFilter: () {
          controller.filterLists(true);
        },
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: AppTabs(
                    tabs: controller.tabs,
                    currentTab: controller.currentTab,
                    changeTab: controller.changeTab,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                sliver: Obx(
                  () {
                    if (controller.isLoading.value) {
                      return const SliverFillRemaining(
                        hasScrollBody: true,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (controller.currentTab.value == 0) {
                      if (controller
                          .salesService.filterInstantSalesTasks.isEmpty) {
                        return const SliverFillRemaining(child: ShowNoData());
                      }
                    } else if (controller.currentTab.value == 1) {
                      if (controller
                          .salesService.filterProfitSalesTasks.isEmpty) {
                        return const SliverFillRemaining(child: ShowNoData());
                      }
                    }
                    return SliverList(
                      delegate: controller.currentTab.value == 0
                          ? SliverChildBuilderDelegate(
                              (context, index) {
                                final month = controller
                                    .salesService.filterInstantSalesTasks.keys
                                    .toList()
                                    .reversed
                                    .toList()[index];

                                final sales = controller.salesService
                                    .filterInstantSalesTasks[month]!.reversed
                                    .toList();
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          month.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium!
                                              .copyWith(
                                                color: AppColors.primaryColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15.sp,
                                              ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5.h),
                                    Container(
                                      height: 1.h,
                                      width: double.infinity,
                                      color: AppColors.primaryColor,
                                    ),
                                    SizedBox(height: 10.h),
                                    ...sales.map(
                                      (instantSales) => InstantSaleCard(
                                        instantSale: instantSales,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              childCount: controller
                                  .salesService.filterInstantSalesTasks.length,
                            )
                          : SliverChildBuilderDelegate(
                              (context, index) {
                                final month = controller
                                    .salesService.filterProfitSalesTasks.keys
                                    .toList()
                                    .reversed
                                    .toList()[index];

                                final sales = controller.salesService
                                    .filterProfitSalesTasks[month]!.reversed
                                    .toList();
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          month.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium!
                                              .copyWith(
                                                color: AppColors.primaryColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15.sp,
                                              ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5.h),
                                    Container(
                                      height: 1.h,
                                      width: double.infinity,
                                      color: AppColors.primaryColor,
                                    ),
                                    SizedBox(height: 10.h),
                                    ...sales.map(
                                      (sale) =>
                                          ProfitSaleCard(profitSale: sale),
                                    ),
                                  ],
                                );
                              },
                              childCount: controller
                                  .salesService.filterProfitSalesTasks.length,
                            ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 50.h)),
            ],
          ),
          Obx(
            () {
              if (!controller.isAddMenuOpen.value)
                return const SizedBox.shrink();
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
          const AddList(),
        ],
      ),
    );
  }
}
