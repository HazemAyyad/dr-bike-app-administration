import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/product_priority_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/all_stock_products_model.dart';
import 'product_location_badge.dart';
import 'stock_product_grid_layout.dart';
import '../controllers/stock_controller.dart';

class BuildProductCard extends GetView<StockController> {
  const BuildProductCard({
    Key? key,
    required this.product,
    required this.isCloseouts,
    this.newComposition,
    this.productIdController,
    this.productNameController,
  }) : super(key: key);

  final AllStockProductsModel product;
  final bool isCloseouts;
  final NewCompositionModel? newComposition;
  final TextEditingController? productIdController;
  final TextEditingController? productNameController;

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: ThemeService.isDark.value
              ? AppColors.whiteColor
              : AppColors.secondaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 11.sp,
          height: 1.2,
        );

    final locationCodeLabel = ProductLocationLabel.withProductCode(
      sectionName: product.storeSectionName,
      shelfNumber: product.shelfNumber,
      productCode: product.productCode,
    );
    final metaStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ThemeService.isDark.value
              ? AppColors.whiteColor.withValues(alpha: 0.85)
              : AppColors.secondaryColor.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
          fontSize: 9.sp,
          letterSpacing: 0.3,
          height: 1.15,
        );

    return Obx(() {
      final tab = controller.currentTab.value;
      final canSelectLocation = !isCloseouts && (tab == 0 || tab == 3);
      final inGroupA = canSelectLocation &&
          controller.isProductInSwapGroupA(product.productId);
      final inGroupB = canSelectLocation &&
          controller.isProductInSwapGroupB(product.productId);
      final isSelected = inGroupA || inGroupB;
      final selectionColor = inGroupB
          ? AppColors.customOrange3
          : AppColors.operationalPurple;

      return GestureDetector(
        onTap: isCloseouts
            ? () async {
                await controller.getProductDetails(
                    productId: product.productId);
                controller.closeoutsProductsId = product.productId;

                controller.closeoutsProductNameController.text =
                    controller.productDetails.value!.nameAr.toString();
                if (newComposition != null) {
                  newComposition!.priceController.text =
                      controller.productDetails.value!.normailPrice.toString();

                  newComposition!.productIdController.text =
                      product.productId.toString();

                  newComposition!.productNameController.text =
                      controller.productDetails.value!.nameAr;
                  controller.calculateGrandTotal();
                }
                productIdController!.text = product.productId.toString();
                productNameController!.text =
                    controller.productDetails.value!.nameAr.toString();

                Get.back();
                controller.update();
              }
            : () {
                if (canSelectLocation &&
                    controller.locationSelectionActive.value) {
                  controller.toggleProductSelection(product.productId);
                  return;
                }
                controller.getProductDetails(productId: product.productId);
                Get.toNamed(AppRoutes.PRODUCTDETAILSSCREEN);
              },
        onLongPress: () async {
          if (isCloseouts) return;
          if (tab == 1) {
            Get.dialog(
              Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'moveToArchive'.tr,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: ThemeService.isDark.value
                                  ? AppColors.whiteColor
                                  : AppColors.secondaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 20.sp,
                            ),
                      ),
                      SizedBox(height: 10.h),
                      AppButton(
                        isSafeArea: false,
                        isLoading: controller.isLoading,
                        text: 'apply'.tr,
                        onPressed: () {
                          controller.moveProductToArchive(
                            context: context,
                            productId: product.closeoutId.toString(),
                            isMove: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (canSelectLocation) {
            if (controller.locationSelectionActive.value) {
              controller.toggleProductSelection(product.productId);
              return;
            }
            await controller.showLocationActionSheetForProduct(
              context,
              product,
            );
          }
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: StockProductGridLayout.minCardHeight.h,
          ),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(80),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: _buildProductImage()),
                    SizedBox(height: 2.h),
                    Text(
                      product.name,
                      style: nameStyle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (locationCodeLabel != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        locationCodeLabel,
                        style: metaStyle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 2.h),
                    _buildStockLine(context),
                  ],
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectionColor,
                        width: 2.5,
                      ),
                      color: selectionColor.withValues(alpha: 0.12),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: selectionColor,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            inGroupB ? 'B' : 'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStockLine(BuildContext context) {
    final lineStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: ThemeService.isDark.value
              ? AppColors.whiteColor
              : AppColors.secondaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 8.sp,
        );

    if (controller.currentTab.value == 2) {
      return Text(
        '${'numberOfProductsUsed'.tr} : ${product.numberOfUsedProducts}',
        style: lineStyle,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (controller.currentTab.value == 1) {
      return Text(
        '${'minimumSale'.tr} : ${product.productMinSalePrice}',
        style: lineStyle,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      '${'stock'.tr} : ${product.stock}',
      style: lineStyle,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProductImage() {
    return ProductPriorityImage(
      imageUrls: product.allImageUrlsInPriority,
      height: 44.h,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8.r),
      placeholder: SizedBox(
        height: 44.h,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      missingPlaceholder: Image.asset(
        AssetsManager.stockImage,
        height: 44.h,
        width: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }
}
