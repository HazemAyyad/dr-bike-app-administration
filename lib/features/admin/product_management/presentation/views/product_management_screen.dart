import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/product_development_model.dart';
import '../controllers/product_management_controller.dart';
import '../widgets/product_management_filter_sheet.dart';
import '../widgets/product_management_toolbar.dart';
import '../widgets/product_management_widget.dart';

class ProductManagementScreen extends GetView<ProductManagementController> {
  const ProductManagementScreen({Key? key}) : super(key: key);

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProductManagementFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'productManagement',
        action: false,
        actions: [
          GetBuilder<ProductManagementController>(
            builder: (controller) {
              final count = controller.activeFilterCount;
              return IconButton(
                highlightColor: Colors.transparent,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 22.sp,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 14.w,
                            minHeight: 14.w,
                          ),
                          child: Text(
                            '$count',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _openFilterSheet(context),
              );
            },
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: 12.h),
          ),
          const SliverToBoxAdapter(
            child: ProductManagementToolbar(),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          GetBuilder<ProductManagementController>(
            builder: (controller) {
              if ((controller.isLoading.value ||
                      controller.isProductsLoading.value) &&
                  controller.displayedProducts.isEmpty) {
                return const _ProductManagementSkeletonList();
              }
              if (controller.displayedProducts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: ShowNoData(),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = controller.displayedProducts[index];
                    final displayStep = item.displayStep;
                    return GestureDetector(
                      onTap: () {
                        controller.openListItem(item);
                        Get.toNamed(AppRoutes.ADDPRODUCTMANAGEMENTSCREEN);
                      },
                      onLongPress: item.hasDevelopment
                          ? () => _showDevelopmentActions(
                                context,
                                controller,
                                item.development!,
                              )
                          : null,
                      child: ProductManagementWidget(
                        currentStep: displayStep,
                        rating: double.tryParse(displayStep) ?? 0,
                        productImage: item.productImage,
                        productImageUrls: item.productImageUrls,
                        productName: item.productName,
                        stageLabel: controller.stepTitle(displayStep),
                      ),
                    );
                  },
                  childCount: controller.displayedProducts.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 58.w,
        width: 58.w,
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
            size: 38.sp,
          ),
        ),
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

void _showDevelopmentActions(
  BuildContext context,
  ProductManagementController controller,
  ProductDevelopmentModel product,
) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 18.h),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.secondaryColor,
                  ),
            ),
            SizedBox(height: 12.h),
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: AppColors.primaryColor,
                size: 22.sp,
              ),
              title: Text('edit'.tr),
              onTap: () {
                Get.back();
                controller.editDevelopment(product);
                Get.toNamed(AppRoutes.ADDPRODUCTMANAGEMENTSCREEN);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.redColor,
                size: 22.sp,
              ),
              title: Text('removeFromDevelopment'.tr),
              onTap: () {
                Get.back();
                _confirmDeleteDevelopment(context, controller, product);
              },
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

void _confirmDeleteDevelopment(
  BuildContext context,
  ProductManagementController controller,
  ProductDevelopmentModel product,
) {
  Get.defaultDialog(
    title: 'removeFromDevelopment'.tr,
    middleText: 'removeFromDevelopmentConfirm'.tr,
    textCancel: 'cancel'.tr,
    textConfirm: 'delete'.tr,
    confirmTextColor: AppColors.whiteColor,
    buttonColor: AppColors.redColor,
    onConfirm: () {
      Get.back();
      controller.deleteDevelopment(product.id.toString());
    },
  );
}

class _ProductManagementSkeletonList extends StatelessWidget {
  const _ProductManagementSkeletonList();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => const _ProductManagementSkeletonCard(),
        childCount: 12,
      ),
    );
  }
}

class _ProductManagementSkeletonCard extends StatelessWidget {
  const _ProductManagementSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final baseColor = ThemeService.isDark.value
        ? AppColors.customGreyColor
        : AppColors.whiteColor2;
    final highlightColor = ThemeService.isDark.value
        ? AppColors.customGreyColor4
        : const Color(0xFFF7F7F7);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      onEnd: () {},
      child: Container(
        height: 35.h,
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              _SkeletonBlock(width: 62.w, height: 8.h, color: highlightColor),
              const Spacer(),
              _SkeletonBlock(width: 110.w, height: 10.h, color: highlightColor),
              SizedBox(width: 10.w),
              _SkeletonBlock(width: 36.w, height: 27.h, color: highlightColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}
