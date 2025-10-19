import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../widgets/order_card.dart';
import '../../widgets/row_text.dart';
import '../controllers/my_orders_controller.dart';
import '../controllers/my_orders_service.dart';

class MyOrdersScreen extends GetView<MyOrdersController> {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'myOrders'.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: Center(
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              height: 32.h,
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.secondaryColor
                    : AppColors.primaryColor,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  RowText(title: 'date'),
                  RowText(title: 'approvedValue'),
                  RowText(title: 'status'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          GetBuilder<MyOrdersController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (MyOrdersService().loansList.isEmpty &&
                  controller.currentTab.value == 0) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              if (MyOrdersService().overtimeList.isEmpty &&
                  controller.currentTab.value == 1) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = controller.currentTab.value == 0
                        ? MyOrdersService().loansList[index]
                        : MyOrdersService().overtimeList[index];
                    return OrderCard(order: order);
                  },
                  childCount: controller.currentTab.value == 0
                      ? MyOrdersService().loansList.length
                      : MyOrdersService().overtimeList.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
