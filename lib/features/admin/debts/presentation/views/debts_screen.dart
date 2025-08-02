import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../controllers/debts_controller.dart';
import '../widgets/app_bar.dart';
import '../widgets/build_debts_credits.dart';
import '../widgets/gave_and_took_button.dart';
import '../widgets/show_debts_widget.dart';

class DebtsScreen extends GetView<DebtsController> {
  const DebtsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: appBar('debts', true, context, controller, '', null),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Get.isDarkMode
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor2,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BuildDebtsAndCredits(
                            icon: Icons.attach_money,
                            label: 'gave'.tr,
                            amount: controller
                                    .dataService
                                    .totalDebtsOwedToUsModel
                                    .value
                                    ?.totalDebtsOwedToUs ??
                                '0',
                            color: Colors.red,
                          ),
                          const SizedBox(width: 16),
                          BuildDebtsAndCredits(
                            icon: Icons.attach_money,
                            label: 'took'.tr,
                            amount: controller.dataService.totalDebtsWeOweModel
                                    .value?.totalDebtsWeOwe ??
                                '0',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  AppTabs(
                    tabs: controller.tabs,
                    currentTab: controller.currentTab,
                    changeTab: controller.changeTab,
                    width: 250.w,
                  ),
                  SizedBox(height: 15.h),
                ],
              ),
            ),
            showDebtsWidget(controller, context),
          ],
        ),
      ),
      bottomNavigationBar: gaveAndTookButton(context),
    );
  }
}
