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
        padding: EdgeInsets.all(5.h),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // صورة المنتج (ShowNetImage: relative path + legacy STORE_DOMAIN host rewrite)
            () {
              final resolved = ShowNetImage.getPhoto(product.image);
              final missing = resolved == AssetsManager.noImageNet ||
                  product.image == 'no image';
              if (missing) {
                return Image.asset(
                  AssetsManager.stockImage,
                  height: 65.h,
                  width: 90.w,
                );
              }
              return ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: CachedNetworkImage(
                      key: ValueKey(
                        '${product.productId}_${resolved.hashCode}',
                      ),
                      cacheKey: '${product.productId}_$resolved',
                      cacheManager: CacheManager(
                        Config(
                          'imagesCache',
                          stalePeriod: const Duration(days: 7),
                          maxNrOfCacheObjects: 100,
                        ),
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        height: 65.h,
                        width: 90.w,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.low,
                          ),
                        ),
                      ),
                      imageUrl: resolved,
                      filterQuality: FilterQuality.low,
                      placeholder: (context, url) => SizedBox(
                        height: 65.h,
                        width: 90.w,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        AssetsManager.stockImage,
                        height: 65.h,
                        width: 90.w,
                      ),
                    ),
                  );
            }(),
            // معلومات المنتج
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.whiteColor
                                : AppColors.secondaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  if (controller.currentTab.value == 2)
                    Text(
                      '${'numberOfProductsUsed'.tr} : ${product.numberOfUsedProducts}',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.whiteColor
                                : AppColors.secondaryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 8.sp,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  if (controller.currentTab.value == 1)
                    Text(
                      '${'minimumSale'.tr} : ${product.productMinSalePrice}',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.whiteColor
                                : AppColors.secondaryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 9.sp,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  if (controller.currentTab.value != 1)
                    Text(
                      '${'stock'.tr} : ${product.stock}',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.whiteColor
                                : AppColors.secondaryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 9.sp,
                          ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
