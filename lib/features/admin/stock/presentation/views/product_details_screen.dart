import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import '../widgets/custom_text_and_dis.dart';
import '../widgets/product_language_details_tabs.dart';
import '../widgets/product_images_slider.dart';
import '../widgets/product_inline_video.dart';
import '../widgets/purchase_price_widget.dart';
import '../widgets/show_wholesale_prices.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/product_details_model.dart';
import '../widgets/product_tag_chip.dart';

Widget _pdKV(
  BuildContext context,
  String titleKey,
  String value,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titleKey.tr,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
      SizedBox(height: 4.h),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.35,
            ),
      ),
    ],
  );
}

Widget _pdSectionCard(
  BuildContext context, {
  required String titleKey,
  required Widget child,
}) {
  return Card(
    elevation: 0,
    color: AdminUiColors.cardBackground(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titleKey.tr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    ),
  );
}

Widget _productDetailsCategoryBlock(
  BuildContext context,
  ProductDetailsModel product,
) {
  final subs = product.productSubCategories;
  var mainName = '';
  final subNames = <String>[];
  if (subs != null && subs.isNotEmpty) {
    mainName = subs.first.mainCategoryName ?? '';
    for (final s in subs) {
      final n = s.subCategoryName ?? '';
      if (n.isNotEmpty) {
        subNames.add(n);
      }
    }
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pdKV(
        context,
        'mainCategory',
        mainName.isEmpty ? '—' : mainName,
      ),
      SizedBox(height: 16.h),
      Text(
        'subCategory'.tr,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
      SizedBox(height: 4.h),
      if (subNames.isEmpty)
        Text(
          '—',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        )
      else
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: subNames
              .map(
                (n) => Chip(
                  label: Text(n),
                  backgroundColor: AdminUiColors.subtleOverlay(context),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
    ],
  );
}

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
    padding: EdgeInsets.only(bottom: 8.h, top: 8.h),
    child: Text(
      keyTr.tr,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    ),
  );
}

class ProductDetailsScreen extends GetView<StockController> {
  const ProductDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: CustomAppBar(
        title: 'productDetails',
        action: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_sharp),
            onPressed: () async {
              if (controller.productDetails.value == null) {
                Get.snackbar(
                  'error'.tr,
                  'productDetailsMissing'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              final ok = await controller.initProductDetails();
              if (!ok) {
                Get.snackbar(
                  'error'.tr,
                  'productDetailsLoadFailed'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
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
                      _pdSectionCard(
                        context,
                        titleKey: 'sectionProductContent',
                        child: ProductLanguageDetailsTabs(product: product),
                      ),
                      if ((product.productCode ?? '').isNotEmpty ||
                          (product.productTags != null &&
                              product.productTags!.isNotEmpty)) ...[
                        SizedBox(height: 24.h),
                        _pdSectionCard(
                          context,
                          titleKey: 'productCodeAndTags',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((product.productCode ?? '').isNotEmpty)
                                _pdKV(
                                  context,
                                  'productCode',
                                  product.productCode!,
                                ),
                              if (product.productTags != null &&
                                  product.productTags!.isNotEmpty) ...[
                                if ((product.productCode ?? '').isNotEmpty)
                                  SizedBox(height: 12.h),
                                Text(
                                  'sectionProductTags'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                ),
                                SizedBox(height: 8.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: product.productTags!
                                      .map(
                                        (t) => ProductTagChip(
                                          name: t.name,
                                          colorHex: t.color,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),
                      _pdSectionCard(
                        context,
                        titleKey: 'sectionCategories',
                        child: _productDetailsCategoryBlock(
                          context,
                          product,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _pdSectionCard(
                        context,
                        titleKey: 'productDetailsSectionPricing',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: CustomTextAndDis(
                                    noSized: true,
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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.file_copy,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 25.sp,
                                        ),
                                        onPressed: () {
                                          Get.dialog(
                                            ShowWholesalePrices(
                                                product: product),
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
                                    discription:
                                        product.price?.toString() ?? '',
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
                                    discription:
                                        product.minSalePrice?.toString() ?? '',
                                  ),
                                ),
                                Flexible(
                                  child: CustomTextAndDis(
                                    noSized: true,
                                    title: 'rotationDateField',
                                    discription:
                                        product.rotationDate?.toString() ?? '',
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
                                    title: 'ThePurchase',
                                    discription: product.purchasePrices !=
                                                null &&
                                            product.purchasePrices!.isNotEmpty
                                        ? product.purchasePrices!.first.price
                                            .toString()
                                        : '',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _pdSectionTitle(context, 'productDetailsSectionSizes'),
                      _SizeColorDetailsTable(product: product),
                      SizedBox(height: 8.h),
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

// ── Sizes & Colors read-only table ───────────────────────────────────────────

class _SizeColorDetailsTable extends StatelessWidget {
  const _SizeColorDetailsTable({required this.product});

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    // Flatten sizes into flat rows. Avoid explicit 'Size' type to prevent
    // conflict with dart:ui.Size — let Dart infer from product.sizes.
    final rows = <_SizeColorRow>[];
    for (final sz in product.sizes ?? []) {
      final sizeName = sz.size ?? '';
      for (final cs in sz.colorSizes ?? []) {
        rows.add(_SizeColorRow(size: sizeName, color: cs));
      }
    }

    if (rows.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'noData'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
        ),
      );
    }

    final dividerColor = Theme.of(context).dividerColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final headerStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10.sp,
          color: onSurface,
        );
    final cellStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          fontSize: 11.sp,
          color: onSurface,
        );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AdminUiColors.cardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 38.h,
          dataRowMinHeight: 42.h,
          dataRowMaxHeight: 54.h,
          columnSpacing: 16.w,
          horizontalMargin: 12.w,
          headingRowColor: WidgetStateProperty.all(
            AdminUiColors.subtleOverlay(context),
          ),
          border: TableBorder(
            horizontalInside: BorderSide(
              color: dividerColor.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          columns: [
            DataColumn(label: Text('size'.tr, style: headerStyle)),
            DataColumn(label: Text('color'.tr, style: headerStyle)),
            DataColumn(label: Text('colorEnglish'.tr, style: headerStyle)),
            DataColumn(label: Text('colorHebrew'.tr, style: headerStyle)),
            DataColumn(label: Text('quantity'.tr, style: headerStyle)),
            DataColumn(label: Text('price'.tr, style: headerStyle)),
            DataColumn(label: Text('wholesalePriceField'.tr, style: headerStyle)),
            DataColumn(label: Text('discountPercentage'.tr, style: headerStyle)),
          ],
          rows: rows.map<DataRow>((r) {
            final cs = r.color;
            return DataRow(cells: [
              DataCell(Text(r.size, style: cellStyle)),
              DataCell(Text(cs.colorAr ?? '', style: cellStyle)),
              DataCell(Text(cs.colorEn ?? '', style: cellStyle)),
              DataCell(Text(cs.colorAbbr ?? '', style: cellStyle)),
              DataCell(Text(cs.stock ?? '', style: cellStyle)),
              DataCell(Text(cs.normailPrice ?? '', style: cellStyle)),
              DataCell(Text(cs.wholesalePrice ?? '', style: cellStyle)),
              DataCell(Text(
                (cs.discount ?? '0') == '0' ? '' : '${cs.discount}%',
                style: cellStyle,
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _SizeColorRow {
  final String size;
  final ColorSize color;
  const _SizeColorRow({required this.size, required this.color});
}
