import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/product_management_controller.dart';
import '../widgets/product_management_widget.dart';

class ProductManagementScreen extends GetView<ProductManagementController> {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'productManagement',
        onPressedAdd: () {
          // controller.resetData();
        },
        action: false,
      ),
      body: CustomScrollView(
        slivers: [
          // tab bar
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
          GetBuilder<ProductManagementController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (controller.currentTab.value == 0 &&
                  controller.searchProductManagement.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: ShowNoData(),
                  ),
                );
              }
              if (controller.currentTab.value == 1 &&
                  controller.searcharchiveProductManagement.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: ShowNoData(),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = controller.currentTab.value == 0
                        ? controller.searchProductManagement.reversed
                            .toList()[index]
                        : controller.searcharchiveProductManagement.reversed
                            .toList()[index];
                    return GestureDetector(
                      onTap: () {
                        if (controller.currentTab.value == 1) {
                          return;
                        }
                        controller.editProduct(
                          id: product.id.toString(),
                          isEditing: true,
                        );
                        Get.toNamed(AppRoutes.ADDPRODUCTMANAGEMENTSCREEN);
                      },
                      child: ProductManagementWidget(
                        currentStep: product.currentStep,
                        productImage: product.productImage,
                        productName: product.productName,
                      ),
                    );
                  },
                  childCount: controller.currentTab.value == 0
                      ? controller.searchProductManagement.length
                      : controller.searcharchiveProductManagement.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 55.h,
        width: 55.w,
        child: FloatingActionButton(
          onPressed: () {
            controller.editProduct(id: '', isEditing: false);
            Get.toNamed(AppRoutes.ADDPRODUCTMANAGEMENTSCREEN);
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
