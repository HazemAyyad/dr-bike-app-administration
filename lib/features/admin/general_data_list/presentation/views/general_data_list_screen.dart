import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';
import '../widgets/global_data.dart';

class GeneralDataListScreen extends GetView<GeneralDataListController> {
  const GeneralDataListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'generalDataList',
        // toDateController: controller.toDateController,
        // fromDateController: controller.fromDateController,
        // employeeNameController: controller.employeeNameController,
        label: 'customerName',

        action: false,
      ),
      body: CustomScrollView(
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
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: SearchBar(
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                leading: const Icon(Icons.search),
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
          GetBuilder<GeneralDataListController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  hasScrollBody: true,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (controller.currentTab.value == 0
                  ? controller.employeeSearch.isEmpty
                  : controller.currentTab.value == 1
                      ? controller.sellersSearch.isEmpty
                      : controller.inCompleteDataSearch.isEmpty) {
                return const SliverFillRemaining(child: ShowNoData());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final employee = controller.currentTab.value == 0
                        ? controller.employeeSearch.reversed.toList()[index]
                        : controller.currentTab.value == 1
                            ? controller.sellersSearch.reversed.toList()[index]
                            : controller.inCompleteDataSearch.reversed
                                .toList()[index];
                    return GlobalData(employee: employee);
                  },
                  childCount: controller.currentTab.value == 0
                      ? controller.employeeSearch.length
                      : controller.currentTab.value == 1
                          ? controller.sellersSearch.length
                          : controller.inCompleteDataSearch.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          controller.isEdit.value = false;
          controller.clearForm();
          // Handle add button press
          Get.toNamed(
            AppRoutes.ADDNEWCUSTOMERSCREEN,
            arguments: {
              'employeeType': '',
              'employeeId': '',
              'sellerId': '',
            },
          );
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
