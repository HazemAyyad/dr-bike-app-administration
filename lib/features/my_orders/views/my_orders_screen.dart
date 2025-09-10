import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/helpers/custom_tab_bar.dart';
import '../controllers/my_orders_controller.dart';
import '../widgets/order_card.dart';
import '../widgets/row_text.dart';

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
      body: Column(
        children: [
          SizedBox(height: 20.h),
          AppTabs(
            tabs: controller.tabs,
            currentTab: controller.currentTab,
            changeTab: controller.changeTab,
          ),
          SizedBox(height: 20.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            height: 32.h,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.secondaryColor
                  : AppColors.primaryColor,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(width: 0.w),
                rowText(context, 'products'),
                SizedBox(width: 10.w),
                rowText(context, 'creationDate'),
                rowText(context, 'status'),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: ListView.builder(
                    key: ValueKey<int>(controller.currentTab.value),
                    itemCount: controller.orders.length,
                    itemBuilder: (context, index) {
                      final order = controller.orders[index];
                      return orderCard(context, order);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
