import 'dart:ui';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';
import '../widgets/add_list.dart';
import '../widgets/my_card.dart';

class SalesScreen extends GetView<SalesController> {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        title: 'sales',
        onPressedAdd: () {
          controller.toggleAddMenu();
        },
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        employeeNameController: controller.employeeNameController,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Stack(
          children: [
            Column(
              children: [
                AppTabs(
                  tabs: controller.tabs,
                  currentTab: controller.currentTab,
                  changeTab: controller.changeTab,
                  width: 250.w,
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : controller.targets.isEmpty
                            ? Center(
                                child: Text(
                                  'noData'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium!
                                      .copyWith(
                                        color: AppColors.customGreyColor,
                                      ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: controller.targets.length,
                                itemBuilder: (context, index) {
                                  final sale = controller.targets[index];
                                  return MyCard(
                                    sale: sale,
                                    controller: controller,
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
            Obx(() {
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
            }),
            AddList(controller: controller),
          ],
        ),
      ),
    );
  }
}
