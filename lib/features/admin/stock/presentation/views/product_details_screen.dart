import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import '../widgets/product_language_details_tabs.dart';
import '../widgets/product_images_slider.dart';
import '../widgets/product_inline_video.dart';
import '../widgets/purchase_price_widget.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/product_details_model.dart';
import '../widgets/product_tag_chip.dart';

class _ProductDetailsHero extends StatelessWidget {
  const _ProductDetailsHero({required this.product});

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = _ProductCategoryMeta.from(product);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductLanguageDetailsTabs(product: product),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if ((product.productCode ?? '').trim().isNotEmpty)
                _ProductMetaChip(
                  icon: Icons.qr_code_2,
                  text: product.productCode!,
                ),
              if (meta.mainName.isNotEmpty)
                _ProductMetaChip(
                  icon: Icons.account_tree_outlined,
                  text: meta.mainName,
                ),
              for (final sub in meta.subNames.take(3))
                _ProductMetaChip(
                  icon: Icons.label_outline,
                  text: sub,
                ),
            ],
          ),
          if (product.productTags != null && product.productTags!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: _PrettyTagsRow(product: product),
            ),
        ],
      ),
    );
  }
}

class _ProductMetaChip extends StatelessWidget {
  const _ProductMetaChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text.trim().isEmpty ? '—' : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrettyTagsRow extends StatelessWidget {
  const _PrettyTagsRow({required this.product});

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    final tags = product.productTags ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Wrap(
        spacing: 7.w,
        runSpacing: 7.h,
        children: tags
            .map(
              (t) => ProductTagChip(
                name: t.name,
                colorHex: t.color,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProductCategoryMeta {
  const _ProductCategoryMeta({
    required this.mainName,
    required this.subNames,
  });

  final String mainName;
  final List<String> subNames;

  factory _ProductCategoryMeta.from(ProductDetailsModel product) {
    final subs = product.productSubCategories;
    final cid = product.categoryId?.trim();
    List<ProductSubCategory>? effectiveSubs = subs;
    if (cid != null && cid.isNotEmpty && subs != null && subs.isNotEmpty) {
      effectiveSubs =
          subs.where((s) => (s.mainCategoryId?.trim() ?? '') == cid).toList();
    }

    var mainName = (product.categoryName ?? '').trim();
    if (mainName.isEmpty && effectiveSubs != null && effectiveSubs.isNotEmpty) {
      mainName = (effectiveSubs.first.mainCategoryName ?? '').trim();
    }

    final subNames = <String>[];
    if (effectiveSubs != null && effectiveSubs.isNotEmpty) {
      for (final s in effectiveSubs) {
        final n = (s.subCategoryName ?? '').trim();
        if (n.isNotEmpty) subNames.add(n);
      }
    }

    return _ProductCategoryMeta(mainName: mainName, subNames: subNames);
  }
}

class _ProductOverviewGrid extends StatelessWidget {
  const _ProductOverviewGrid({required this.product});

  final ProductDetailsModel product;

  bool get _isAdmin => userType.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    final cost =
        product.purchasePrices != null && product.purchasePrices!.isNotEmpty
            ? product.purchasePrices!.first.price.toString()
            : '—';
    final items = [
      _MetricData(Icons.inventory_2_outlined, 'stock'.tr,
          product.stock?.toString() ?? '0'),
      _MetricData(Icons.warning_amber_rounded, 'minimumStock'.tr,
          product.minStock?.toString() ?? '—'),
      _MetricData(Icons.sell_outlined, 'retailPrice'.tr,
          product.normailPrice?.toString() ?? '—'),
      _MetricData(
          Icons.percent, 'discountPercentage'.tr, '${product.discount ?? 0}%'),
      _MetricData(Icons.price_change_outlined, 'minimumSalePrice'.tr,
          product.minSalePrice?.toString() ?? '—'),
      if (_isAdmin)
        _MetricData(Icons.shopping_bag_outlined, 'ThePurchase'.tr, cost,
            onTap: () => Get.dialog(ShowPurchasePrice(product: product))),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (context, index) => _MetricCard(data: items[index]),
    );
  }
}

class _MetricData {
  const _MetricData(this.icon, this.label, this.value, {this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 18.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.58),
                      ),
                ),
                SizedBox(height: 3.h),
                Text(
                  data.value.trim().isEmpty ? '—' : data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          if (data.onTap != null)
            Icon(
              Icons.open_in_new,
              size: 15.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );

    if (data.onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: data.onTap,
        child: child,
      ),
    );
  }
}

class _ProductExtraInfoPanel extends StatelessWidget {
  const _ProductExtraInfoPanel({required this.product});

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    final soldWithPaper =
        product.isSoldWithPaper == 1 || product.isSoldWithPaper == '1';
    final rows = [
      _InfoLine('wholesalePriceField'.tr, product.wholesalePrice ?? '—'),
      _InfoLine('listPriceField'.tr, product.price?.toString() ?? '—'),
      _InfoLine('productModel'.tr, product.model ?? '—'),
      _InfoLine('manufactureYear'.tr, product.manufactureYear ?? '—'),
      _InfoLine('rateLabel'.tr, product.rate ?? '—'),
      _InfoLine(
          'rotationDateField'.tr, product.rotationDate?.toString() ?? '—'),
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          for (final row in rows) _InfoRow(line: row),
          Divider(height: 18.h),
          Row(
            children: [
              Icon(
                soldWithPaper ? Icons.check_circle : Icons.cancel,
                size: 20.sp,
                color: soldWithPaper ? Colors.green.shade700 : Colors.grey,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'isForcedSale'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.line});

  final _InfoLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.62),
                  ),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              line.value.trim().isEmpty ? '—' : line.value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
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
                      _ProductDetailsHero(product: product),
                      SizedBox(height: 14.h),
                      _ProductOverviewGrid(product: product),
                      SizedBox(height: 14.h),
                      _ProductExtraInfoPanel(product: product),
                      SizedBox(height: 18.h),
                      _pdSectionTitle(context, 'productDetailsSectionSizes'),
                      _SizeColorDetailsTable(product: product),
                      SizedBox(height: 18.h),
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

  void _showColorLanguages(BuildContext context, ColorSize color) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(18.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.translate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'اللغات الاخرى',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Get.back,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _colorLanguageRow(
                context,
                'colorEnglish'.tr,
                color.colorEn,
              ),
              SizedBox(height: 10.h),
              _colorLanguageRow(
                context,
                'colorHebrew'.tr,
                color.colorAbbr,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorLanguageRow(
    BuildContext context,
    String title,
    String? value,
  ) {
    final display = (value ?? '').trim().isEmpty ? '—' : value!.trim();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              display,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      );
    }

    final grouped = <String, List<ColorSize>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.size.trim().isEmpty ? '—' : row.size, () => []);
      grouped[row.size.trim().isEmpty ? '—' : row.size]!.add(row.color);
    }

    return Column(
      children: grouped.entries
          .map(
            (entry) => _SizeColorCard(
              size: entry.key,
              colors: entry.value,
              onTranslate: (color) => _showColorLanguages(context, color),
            ),
          )
          .toList(),
    );
  }
}

class _SizeColorCard extends StatelessWidget {
  const _SizeColorCard({
    required this.size,
    required this.colors,
    required this.onTranslate,
  });

  final String size;
  final List<ColorSize> colors;
  final ValueChanged<ColorSize> onTranslate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 18.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${'size'.tr}: $size',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AdminUiColors.subtleOverlay(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${colors.length} ${'color'.tr}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          for (final color in colors) ...[
            _ColorSizeLine(color: color, onTranslate: onTranslate),
            if (color != colors.last) SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}

class _ColorSizeLine extends StatelessWidget {
  const _ColorSizeLine({
    required this.color,
    required this.onTranslate,
  });

  final ColorSize color;
  final ValueChanged<ColorSize> onTranslate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              color.colorAr?.trim().isEmpty == false ? color.colorAr! : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          _MiniStat(label: 'quantity'.tr, value: color.stock ?? '0'),
          _MiniStat(label: 'price'.tr, value: color.normailPrice ?? '—'),
          IconButton(
            tooltip: 'اللغات الاخرى',
            icon: Icon(
              Icons.translate,
              size: 18.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => onTranslate(color),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.58),
                ),
          ),
          SizedBox(height: 2.h),
          Text(
            value.trim().isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _SizeColorRow {
  final String size;
  final ColorSize color;
  const _SizeColorRow({required this.size, required this.color});
}
