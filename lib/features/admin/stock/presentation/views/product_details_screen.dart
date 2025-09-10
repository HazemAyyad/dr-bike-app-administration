import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_chechbox.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import '../widgets/custom_text_and_dis.dart';
import '../widgets/product_images_slider.dart';
import '../widgets/purchase_price_widget.dart';
import '../widgets/show_wholesale_prices.dart';
import 'web_view_test.dart';

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
              Get.to(() => const EditProductWebView());
              // controller.initProductDetails();
              // Get.toNamed(AppRoutes.EDITPRODUCTSCREEN);
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      CustomTextAndDis(
                        title: 'productName',
                        discription: product.nameAr,
                      ),
                      CustomTextAndDis(
                        title: 'productDetails',
                        discription: product.descriptionAr ?? '',
                      ),
                      CustomTextAndDis(
                        title: 'mainCategory',
                        discription: product.productSubCategories != null &&
                                product.productSubCategories!.isNotEmpty
                            ? product
                                .productSubCategories!.first.mainCategoryName!
                            : '',
                      ),
                      CustomTextAndDis(
                        title: 'subCategory',
                        discription: product.productSubCategories != null &&
                                product.productSubCategories!.isNotEmpty
                            ? product
                                .productSubCategories!.first.subCategoryName!
                            : '',
                      ),
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
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          height: 1.h,
                          width: 300.w,
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor3,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
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
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          height: 1.h,
                          width: 300.w,
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor3,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
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
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          height: 1.h,
                          width: 300.w,
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor3,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      ...product.sizes!.map(
                        (e) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextAndDis(
                              noSized: true,
                              title: 'size',
                              discription: e.size.toString(),
                            ),
                            ...e.colorSizes!.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: CustomTextAndDis(
                                        noSized: true,
                                        title: 'color',
                                        discription: e.colorAr.toString(),
                                      ),
                                    ),
                                    CustomTextAndDis(
                                      noSized: true,
                                      discriptionColor: const Color.fromARGB(
                                          255, 95, 77, 255),
                                      title: 'stock',
                                      discription: e.stock.toString(),
                                    ),
                                    SizedBox(width: 5.w),
                                    CustomTextAndDis(
                                      noSized: true,
                                      discriptionColor: Colors.green,
                                      title: 'price',
                                      discription: e.normailPrice.toString(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          height: 1.h,
                          width: 300.w,
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor3,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
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
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          height: 1.h,
                          width: 300.w,
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor3,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'productRotationDate'.tr,
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
                          SizedBox(width: 10.w),
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                      CustomCheckBox(
                        title: 'isForcedSale',
                        value:
                            product.isSoldWithPaper == 1 ? true.obs : false.obs,
                        onChanged: (value) {
                          // product.isSoldWithPaper = value! ? 1 : 0;
                        },
                      ),
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
                      SizedBox(height: 50.h),
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
