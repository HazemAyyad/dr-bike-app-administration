import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';
import '../widgets/global_data.dart';

class GeneralDataListScreen extends GetView<GeneralDataListController> {
  const GeneralDataListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'generalDataList',
        toDateController: controller.toDateController,
        fromDateController: controller.fromDateController,
        employeeNameController: controller.employeeNameController,
        label: 'customerName',
        onPressedAdd: () {
          controller.isEdit.value = false;
          controller.clearForm();

          // Handle add button press
          Get.toNamed(AppRoutes.ADDNEWCUSTOMERSCREEN);
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
                // width: 270.w,
              ),
            ),
          ),
          Obx(
            () {
              if (controller.isLoading.value) {
                return SliverFillRemaining(
                  hasScrollBody: true,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (controller.currentTab.value == 0
                  ? controller.generalDataServes.employeeDataList.isEmpty
                  : controller.currentTab.value == 1
                      ? controller.generalDataServes.sellersDataList.isEmpty
                      : controller
                          .generalDataServes.inCompleteDataList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: true,
                  child: ShowNoData(),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final employee = controller.currentTab.value == 0
                        ? controller.generalDataServes.employeeDataList.reversed
                            .toList()[index]
                        : controller.currentTab.value == 1
                            ? controller
                                .generalDataServes.sellersDataList.reversed
                                .toList()[index]
                            : controller
                                .generalDataServes.inCompleteDataList.reversed
                                .toList()[index];
                    return Column(
                      children: [
                        SizedBox(height: index == 0 ? 10.h : 0.h),
                        GlobalData(employee: employee),
                      ],
                    );
                  },
                  childCount: controller.currentTab.value == 0
                      ? controller.generalDataServes.employeeDataList.length
                      : controller.currentTab.value == 1
                          ? controller.generalDataServes.sellersDataList.length
                          : controller
                              .generalDataServes.inCompleteDataList.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
