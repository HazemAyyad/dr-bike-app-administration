import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import '../widgets/custom_text_and_dis.dart';
import '../widgets/product_images_slider.dart';
import '../widgets/product_inline_video.dart';
import '../widgets/purchase_price_widget.dart';
import '../widgets/show_wholesale_prices.dart';
import '../../../../../routes/app_routes.dart';

Widget _pdDivider(BuildContext context) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h),
    child: Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
    ),
  );
}

Widget _pdSectionTitle(BuildContext context, String keyTr) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
    child: Text(
      keyTr.tr,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryColor,
          ),
    ),
  );
}

class ProductDetailsScreen extends GetView<StockController> {
  const ProductDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'productDetails',
        action: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_sharp),
            onPressed: () {
              controller.initProductDetails();
              Get.toNamed(AppRoutes.EDITPRODUCTSCREEN);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // خيارات الأسعار
          Obx(
            () {
              if (controller.isProductLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.productDetails.value == null) {
                return const SliverFillRemaining(
                  child: ShowNoData(),
                );
              }
              final product = controller.productDetails.value!;
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 8.h),
                      _pdSectionTitle(context, 'productDetailsSectionInfo'),
                      CustomTextAndDis(
                        title: 'productName',
                        discription: product.nameAr,
                      ),
                      CustomTextAndDis(
                        title: 'nameEnglish',
                        discription: product.nameEng,
                      ),
                      CustomTextAndDis(
                        title: 'nameHebrew',
                        discription: product.nameAbree ?? '',
                      ),
                      CustomTextAndDis(
                        title: 'productDetails',
                        discription: product.descriptionAr ?? '',
                      ),
                      CustomTextAndDis(
                        title: 'descriptionEnglish',
                        discription: product.descriptionEng ?? '',
                      ),
                      CustomTextAndDis(
                        title: 'descriptionHebrew',
                        discription: product.descriptionAbree ?? '',
                      ),
                      CustomTextAndDis(
                        title: 'subCategory',
                        discription: product.productSubCategories != null &&
                                product.productSubCategories!.isNotEmpty
                            ? product.productSubCategories!
                                .map((e) => e.subCategoryName ?? '')
                                .where((e) => e.isNotEmpty)
                                .join('، ')
                            : '',
                      ),
                      CustomTextAndDis(
                        title: 'mainCategory',
                        discription: product.productSubCategories != null &&
                                product.productSubCategories!.isNotEmpty
                            ? product.productSubCategories!.first.mainCategoryName ?? ''
                            : '',
                      ),
                      _pdSectionTitle(context, 'productDetailsSectionPricing'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 1,
                            child: CustomTextAndDis(
                              noSized: true,
                              discriptionColor:
                                  const Color.fromARGB(255, 95, 77, 255),
                              title: 'stock',
                              discription: controller
                                  .productDetails.value!.stock
                                  .toString(),
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: CustomTextAndDis(
                              noSized: true,
                              titleColor: Colors.white,
                              discriptionColor:
                                  const Color.fromARGB(255, 95, 77, 255),
                              title: 'minimumStock',
                              discription: product.minStock.toString(),
                            ),
                          ),
                        ],
                      ),
                      _pdDivider(context),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Text(
                                  'wholesalePrices'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w700,
                                          color: ThemeService.isDark.value
                                              ? AppColors.customGreyColor6
                                              : AppColors.customGreyColor),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.file_copy,
                                    color: AppColors.primaryColor,
                                    size: 25.sp,
                                  ),
                                  onPressed: () {
                                    Get.dialog(
                                      ShowWholesalePrices(product: product),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: CustomTextAndDis(
                              noSized: true,
                              discriptionColor: Colors.green,
                              title: 'retailPrice',
                              discription: product.normailPrice.toString(),
                            ),
                          ),
                        ],
                      ),
                      CustomTextAndDis(
                        title: 'wholesalePriceField',
                        discription: product.wholesalePrice ?? '',
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CustomTextAndDis(
                              noSized: true,
                              title: 'manufactureYear',
                              discription: product.manufactureYear ?? '',
                            ),
                          ),
                          Flexible(
                            child: CustomTextAndDis(
                              noSized: true,
                              title: 'productModel',
                              discription: product.model ?? '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CustomTextAndDis(
                              noSized: true,
                              title: 'rateLabel',
                              discription: product.rate ?? '',
                            ),
                          ),
                          Flexible(
                            child: CustomTextAndDis(
                              noSized: true,
                              title: 'listPriceField',
                              discription: product.price?.toString() ?? '',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CustomTextAndDis(
                              noSized: true,
                              title: 'minSalePriceField',
                              discription: product.minSalePrice?.toString() ?? '',
                            ),
                          ),
                          Flexible(
                            child: CustomTextAndDis(
                              noSized: true,
                              title: 'rotationDateField',
                              discription: product.rotationDate?.toString() ?? '',
                            ),
                          ),
                        ],
                      ),
                      _pdDivider(context),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 1,
                            child: CustomTextAndDis(
                              noSized: true,
                              title: 'discountPercentage',
                              discription: '${product.discount}%',
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: CustomTextAndDis(
                              noSized: true,
                              discriptionColor: Colors.green,
                              title: 'ThePurchase',
                              discription: product.purchasePrices != null &&
                                      product.purchasePrices!.isNotEmpty
                                  ? product.purchasePrices!.first.price
                                      .toString()
                                  : '',
                            ),
                          ),
                        ],
                      ),
                      _pdDivider(context),
                      _pdSectionTitle(context, 'productDetailsSectionSizes'),
                      ...(product.sizes ?? []).map(
                        (e) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextAndDis(
                              noSized: true,
                              title: 'size',
                              discription: e.size.toString(),
                            ),
                            ...(e.colorSizes ?? []).map(
                              (cs) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: CustomTextAndDis(
                                            noSized: true,
                                            title: 'color',
                                            discription: cs.colorAr.toString(),
                                          ),
                                        ),
                                        CustomTextAndDis(
                                          noSized: true,
                                          discriptionColor: const Color.fromARGB(
                                              255, 95, 77, 255),
                                          title: 'stock',
                                          discription: cs.stock.toString(),
                                        ),
                                        SizedBox(width: 5.w),
                                        CustomTextAndDis(
                                          noSized: true,
                                          discriptionColor: Colors.green,
                                          title: 'price',
                                          discription:
                                              cs.normailPrice.toString(),
                                        ),
                                      ],
                                    ),
                                    if ((cs.colorEn ?? '').isNotEmpty ||
                                        (cs.colorAbbr ?? '').isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4.h),
                                        child: Text(
                                          '${'colorEnglish'.tr}: ${cs.colorEn ?? '—'}  |  ${'colorHebrew'.tr}: ${cs.colorAbbr ?? '—'}',
                                          style: Theme.of(context)
                                              .textTheme.bodySmall,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _pdDivider(context),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'purchasePrice'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                            fontSize: 17.sp,
                                            fontWeight: FontWeight.w700,
                                            color: ThemeService.isDark.value
                                                ? AppColors.customGreyColor6
                                                : AppColors.customGreyColor),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.file_copy,
                                    color: AppColors.primaryColor,
                                    size: 25.sp,
                                  ),
                                  onPressed: () {
                                    Get.dialog(
                                      ShowPurchasePrice(product: product),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: CustomTextAndDis(
                              noSized: true,
                              discriptionColor: Colors.green,
                              title: 'minimumSalePrice',
                              discription: product.minSalePrice.toString(),
                            ),
                          ),
                        ],
                      ),
                      _pdDivider(context),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.h, top: 2.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              product.isSoldWithPaper == 1 ||
                                      product.isSoldWithPaper == '1'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 22.sp,
                              color: product.isSoldWithPaper == 1 ||
                                      product.isSoldWithPaper == '1'
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'isForcedSale'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _pdDivider(context),
                      _pdSectionTitle(context, 'productDetailsSectionMedia'),
                      product.viewImages != null &&
                              product.viewImages!.isNotEmpty
                          ? ProductImagesSlider(
                              title: 'productImages',
                              images: product.viewImages!,
                            )
                          : const SizedBox.shrink(),
                      product.normalImages != null &&
                              product.normalImages!.isNotEmpty
                          ? ProductImagesSlider(
                              title: 'naturalImages',
                              images: product.normalImages!,
                            )
                          : const SizedBox.shrink(),
                      product.image3d != null && product.image3d!.isNotEmpty
                          ? ProductImagesSlider(
                              title: 'dimensionImages',
                              images: product.image3d!,
                            )
                          : const SizedBox.shrink(),
                      Builder(
                        builder: (context) {
                          final rawVideo = product.videoUrl?.toString().trim();
                          if (rawVideo == null ||
                              rawVideo.isEmpty ||
                              rawVideo == 'null') {
                            return const SizedBox.shrink();
                          }
                          final resolved = ShowNetImage.getPhoto(rawVideo);
                          if (resolved == AssetsManager.noImageNet ||
                              resolved.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: 22.sp,
                                    color: AppColors.secondaryColor,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'productVideo'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              ProductInlineVideo(videoUrl: resolved),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
