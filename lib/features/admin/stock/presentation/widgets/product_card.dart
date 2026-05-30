import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/all_stock_products_model.dart';
import 'product_tags_overflow.dart';
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

    return GestureDetector(
      onTap: isCloseouts
          ? () async {
              await controller.getProductDetails(productId: product.productId);
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
              controller.getProductDetails(productId: product.productId);
              Get.toNamed(AppRoutes.PRODUCTDETAILSSCREEN);
            },
      onLongPress: () {
        if (controller.currentTab.value == 1) {
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
        }
      },
      child: Container(
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
            if (product.productCode.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                product.productCode,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor.withValues(alpha: 0.85)
                          : AppColors.secondaryColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 9.sp,
                      letterSpacing: 0.3,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (product.tags.isNotEmpty) ...[
              SizedBox(height: 2.h),
              ProductTagsOverflow(tags: product.tags, dense: true),
            ],
            SizedBox(height: 2.h),
            _buildStockLine(context),
          ],
        ),
      ),
    );
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
    final imageSource = _preferredImageSource();
    final resolved = ShowNetImage.getThumbnailPhoto(imageSource);
    final original = ShowNetImage.getPhoto(imageSource);
    final missing =
        resolved == AssetsManager.noImageNet || imageSource == 'no image';

    if (missing) {
      return Image.asset(
        AssetsManager.stockImage,
        height: 44.h,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: CachedNetworkImage(
        key: ValueKey('${product.productId}_${resolved.hashCode}'),
        cacheKey: '${product.productId}_$resolved',
        cacheManager: CacheManager(
          Config(
            'imagesCache',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        ),
        height: 44.h,
        width: double.infinity,
        fit: BoxFit.cover,
        imageUrl: resolved,
        filterQuality: FilterQuality.low,
        placeholder: (context, url) => SizedBox(
          height: 44.h,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => CachedNetworkImage(
          imageUrl: original,
          height: 44.h,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Image.asset(
            AssetsManager.stockImage,
            height: 44.h,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  String _preferredImageSource() {
    for (final image in [
      product.viewImage,
      product.normalImage,
      product.image,
    ]) {
      final trimmed = image.trim();
      if (trimmed.isNotEmpty && trimmed != 'no image') {
        return trimmed;
      }
    }
    return 'no image';
  }
}
