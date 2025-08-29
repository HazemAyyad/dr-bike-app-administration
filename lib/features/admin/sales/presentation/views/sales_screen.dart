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
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        employeeNameController: controller.employeeNameController,
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
                      return SliverFillRemaining(
                        hasScrollBody: true,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (controller.currentTab.value == 0) {
                      if (controller.salesService.instantSalesTasks.isEmpty) {
                        return SliverFillRemaining(child: ShowNoData());
                      }
                    } else if (controller.currentTab.value == 1) {
                      if (controller.profitSalesTasks.isEmpty) {
                        return SliverFillRemaining(child: ShowNoData());
                      }
                    }
                    return SliverList(
                      delegate: controller.currentTab.value == 0
                          ? SliverChildBuilderDelegate(
                              (context, index) {
                                final instantSales = controller
                                    .salesService.instantSalesTasks.reversed
                                    .toList()[index];
                                return Column(
                                  children: [
                                    SizedBox(height: index == 0 ? 35.h : 0.h),
                                    InstantSaleCard(instantSale: instantSales),
                                  ],
                                );
                              },
                              childCount: controller
                                  .salesService.instantSalesTasks.length,
                            )
                          : SliverChildBuilderDelegate(
                              (context, index) {
                                final month = controller.profitSalesTasks.keys
                                    .toList()
                                    .reversed
                                    .toList()[index];

                                final sales = controller
                                    .profitSalesTasks[month]!.reversed
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
                              childCount: controller.profitSalesTasks.length,
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
              if (!controller.isAddMenuOpen.value) return SizedBox.shrink();
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
          AddList(),
        ],
      ),
    );
  }
}
