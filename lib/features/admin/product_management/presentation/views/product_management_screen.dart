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
import '../widgets/product_management_widget.dart';

class ProductManagementScreen extends GetView<ProductManagementController> {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'productManagement',
        action: false,
        actions: [
          IconButton(
            highlightColor: Colors.transparent,
            icon: Icon(
              Icons.calendar_today_outlined,
              size: 22.sp,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
            onPressed: () {},
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: 12.h),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: _ProductManagementTabs(
                controller: controller,
                textTheme: textTheme,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 47.w),
              child: _SearchField(
                onChanged: controller.searchBar,
                textTheme: textTheme,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12.h)),
          GetBuilder<ProductManagementController>(
            builder: (controller) {
              if (controller.currentTab.value == 0 &&
                  controller.isProductsLoading.value &&
                  controller.searchProducts.isEmpty) {
                return const _ProductManagementSkeletonList();
              }
              if (controller.currentTab.value == 1 &&
                  controller.isLoading.value) {
                return const _ProductManagementSkeletonList();
              }
              if (controller.currentTab.value == 2 &&
                  controller.isLoading.value) {
                return const _ProductManagementSkeletonList();
              }
              if (controller.currentTab.value == 0 &&
                  controller.searchProducts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: ShowNoData(),
                  ),
                );
              }
              if (controller.currentTab.value == 1 &&
                  controller.searchProductManagement.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: ShowNoData(),
                  ),
                );
              }
              if (controller.currentTab.value == 2 &&
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
                    final tab = controller.currentTab.value;
                    final stockProduct =
                        tab == 0 ? controller.searchProducts[index] : null;
                    final productDevelopment = tab == 1
                        ? controller.searchProductManagement[index]
                        : tab == 2
                            ? controller.searcharchiveProductManagement[index]
                            : null;
                    final stockDevelopment = tab == 0 && stockProduct != null
                        ? controller.developmentForProduct(stockProduct.id)
                        : null;
                    final displayStep = productDevelopment?.currentStep ??
                        stockDevelopment?.currentStep ??
                        (tab == 0 ? '0' : '4');
                    return GestureDetector(
                      onTap: () {
                        if (tab == 2) {
                          return;
                        }
                        if (tab == 1) {
                          controller.editProduct(
                            id: productDevelopment!.id.toString(),
                            isEditing: true,
                          );
                          Get.toNamed(AppRoutes.ADDPRODUCTMANAGEMENTSCREEN);
                        } else {
                          controller.selectProductForDevelopment(stockProduct!);
                          Get.toNamed(AppRoutes.ADDPRODUCTMANAGEMENTSCREEN);
                        }
                      },
                      onLongPress: tab == 1
                          ? () => _showDevelopmentActions(
                                context,
                                controller,
                                productDevelopment!,
                              )
                          : null,
                      child: ProductManagementWidget(
                        currentStep: displayStep,
                        rating: double.tryParse(displayStep) ?? 0,
                        productImage: productDevelopment?.productImage ??
                            stockProduct?.imageUrl ??
                            '',
                        productName: productDevelopment?.productName ??
                            stockProduct?.nameAr ??
                            '',
                        stageLabel: productDevelopment == null
                            ? ''
                            : controller
                                .stepTitle(productDevelopment.currentStep),
                        onHistoryTap: tab == 1
                            ? () => _showDevelopmentHistory(
                                  context,
                                  productDevelopment!,
                                )
                            : null,
                      ),
                    );
                  },
                  childCount: controller.currentTab.value == 0
                      ? controller.searchProducts.length
                      : controller.currentTab.value == 1
                          ? controller.searchProductManagement.length
                          : controller.searcharchiveProductManagement.length,
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

void _showDevelopmentHistory(
  BuildContext context,
  ProductDevelopmentModel product,
) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.72.sh),
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
              'productDevelopmentLog'.tr,
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
            if (product.activityLogs.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 18.h),
                child: Text(
                  'noData'.tr,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: product.activityLogs.length,
                  separatorBuilder: (_, __) => Divider(height: 16.h),
                  itemBuilder: (context, index) {
                    final log = product.activityLogs[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.history_rounded,
                        color: AppColors.primaryColor,
                        size: 22.sp,
                      ),
                      title: Text(
                        log.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${log.userName} • ${log.createdAt}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
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

class _ProductManagementTabs extends StatelessWidget {
  const _ProductManagementTabs({
    required this.controller,
    required this.textTheme,
  });

  final ProductManagementController controller;
  final TextStyle textTheme;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductManagementController>(
      builder: (_) => Container(
        padding: EdgeInsets.all(4.w),
        width: 300.w,
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Row(
          children: List.generate(controller.tabs.length, (index) {
            final selected = controller.currentTab.value == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.changeTab(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.whiteColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withAlpha(24),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    controller.tabs[index].tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.copyWith(
                      color: selected
                          ? AppColors.secondaryColor
                          : AppColors.customGreyColor5,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.onChanged,
    required this.textTheme,
  });

  final ValueChanged<String> onChanged;
  final TextStyle textTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: TextField(
        textAlign: TextAlign.right,
        onChanged: onChanged,
        style: textTheme.copyWith(
          fontSize: 15.sp,
          color: ThemeService.isDark.value
              ? AppColors.whiteColor
              : AppColors.secondaryColor,
        ),
        decoration: InputDecoration(
          hintText: 'search'.tr,
          hintStyle: textTheme.copyWith(
            color: AppColors.customGreyColor5,
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: Icon(
            Icons.search,
            color: AppColors.secondaryColor,
            size: 25.sp,
          ),
          filled: true,
          fillColor: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          contentPadding: EdgeInsets.symmetric(horizontal: 18.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
