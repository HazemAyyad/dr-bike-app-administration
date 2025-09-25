import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/bills_controller.dart';
import '../../controllers/return_purchases_controller.dart';
import '../../widgets/return_purchases_widgets/return_purchases_list.dart';

class ReturnPurchasesScreen extends GetView<ReturnPurchasesController> {
  const ReturnPurchasesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'returnPurchase', action: false),
      body: CustomScrollView(
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
          GetBuilder<ReturnPurchasesController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.currentTab.value == 0 &&
                  controller.returnPurchasesSearch.isEmpty) {
                return const SliverFillRemaining(
                    child: Center(child: ShowNoData()));
              }
              if (controller.currentTab.value == 1 &&
                  controller.deliveredPurchasesSearch.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, section) {
                    final month = controller.currentTab.value == 0
                        ? controller.returnPurchasesSearch.keys
                            .toList()
                            .reversed
                            .toList()[section]
                        : controller.deliveredPurchasesSearch.keys
                            .toList()
                            .reversed
                            .toList()[section];
                    final bills = controller.currentTab.value == 0
                        ? controller.returnPurchasesSearch[month]!.reversed
                            .toList()
                        : controller.deliveredPurchasesSearch[month]!.reversed
                            .toList();

                    return ReturnPurchasesList(
                      month: month,
                      bills: bills,
                    );
                  },
                  childCount: controller.currentTab.value == 0
                      ? controller.returnPurchasesSearch.length
                      : controller.deliveredPurchasesSearch.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 55.h,
        width: 55.w,
        child: FloatingActionButton(
          onPressed: () {
            Get.find<BillsController>().isaddNewBill = '3';
            Get.toNamed(AppRoutes.ADDNEWBILLSCREEN);
          },
          backgroundColor: AppColors.secondaryColor,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add,
            color: AppColors.whiteColor,
            size: 42.sp,
          ),
        ),
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
