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
import '../widgets/show_wholesale_prices.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/product_details_model.dart';
import '../widgets/product_location_badge.dart';
import '../widgets/product_screen_shared_widgets.dart';
import '../widgets/product_stock_movements_link.dart';
import '../widgets/stock_skeleton_widgets.dart';
import '../widgets/stock_quick_adjust_sheet.dart';
import '../widgets/stock_variant_adjust_sheet.dart';

class _ProductDetailsHero extends StatelessWidget {
  const _ProductDetailsHero({required this.product});

  final ProductDetailsModel product;

  @override
  Widget build(BuildContext context) {
    final meta = _ProductCategoryMeta.from(product);
    final locationCodeLabel = ProductLocationLabel.withProductCode(
      sectionName: product.storeSectionName,
      productCode: product.productCode,
    );
    return ProductHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductLanguageDetailsTabs(product: product),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              if (locationCodeLabel != null)
                ProductMetaChip(
                  icon: Icons.qr_code_2,
                  text: locationCodeLabel,
                ),
              if (meta.mainName.isNotEmpty)
                ProductMetaChip(
                  icon: Icons.account_tree_outlined,
                  text: meta.mainName,
                ),
              for (final sub in meta.subNames)
                ProductMetaChip(
                  icon: Icons.label_outline,
                  text: sub,
                ),
            ],
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = userType.toLowerCase() == 'admin';
    final cost =
        product.purchasePrices != null && product.purchasePrices!.isNotEmpty
            ? product.purchasePrices!.first.price.toString()
            : '—';
    final items = [
      ProductMetricData(Icons.inventory_2_outlined, 'stock'.tr,
          product.stock?.toString() ?? '0'),
      ProductMetricData(Icons.warning_amber_rounded, 'minimumStock'.tr,
          product.minStock?.toString() ?? '—'),
      ProductMetricData(Icons.sell_outlined, 'retailPrice'.tr,
          product.normailPrice?.toString() ?? '—'),
      ProductMetricData(Icons.storefront_outlined, 'wholesalePriceField'.tr,
          product.wholesalePrice?.toString() ?? '—',
          onTap: () => Get.dialog(ShowWholesalePrices(product: product))),
      ProductMetricData(
          Icons.percent, 'discountPercentage'.tr, '${product.discount ?? 0}%'),
      ProductMetricData(Icons.price_change_outlined, 'minimumSalePrice'.tr,
          product.minSalePrice?.toString() ?? '—'),
      if (isAdmin)
        ProductMetricData(Icons.shopping_bag_outlined, 'ThePurchase'.tr, cost,
            onTap: () => Get.dialog(ShowPurchasePrice(product: product))),
      ProductMetricData(Icons.price_check_outlined, 'listPriceField'.tr,
          product.price?.toString() ?? '—'),
      ProductMetricData(Icons.two_wheeler_outlined, 'productModel'.tr,
          product.model?.toString() ?? '—'),
      ProductMetricData(Icons.calendar_month_outlined, 'manufactureYear'.tr,
          product.manufactureYear?.toString() ?? '—'),
      ProductMetricData(Icons.star_rate_rounded, 'rateLabel'.tr,
          product.rate?.toString() ?? '—'),
      ProductMetricData(Icons.update_rounded, 'rotationDateField'.tr,
          product.rotationDate?.toString() ?? '—'),
      ProductMetricData(
        product.isSoldWithPaper == 1 || product.isSoldWithPaper == '1'
            ? Icons.menu_book_rounded
            : Icons.menu_book_outlined,
        'isForcedSale'.tr,
        product.isSoldWithPaper == 1 || product.isSoldWithPaper == '1'
            ? 'مفعل'
            : 'غير مفعل',
        trailingIcon: Icons.gavel_rounded,
      ),
    ];
    return ProductOverviewMetricGrid(items: items);
  }
}

class _ProductMediaSection extends StatefulWidget {
  const _ProductMediaSection({required this.product});

  final ProductDetailsModel product;

  @override
  State<_ProductMediaSection> createState() => _ProductMediaSectionState();
}

class _ProductMediaSectionState extends State<_ProductMediaSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cards = <Widget>[];

    if (product.viewImages != null && product.viewImages!.isNotEmpty) {
      cards.add(
        ProductImagesSlider(
          title: 'productImages',
          images: product.viewImages!,
          compact: true,
        ),
      );
    }
    if (product.normalImages != null && product.normalImages!.isNotEmpty) {
      cards.add(
        ProductImagesSlider(
          title: 'naturalImages',
          images: product.normalImages!,
          compact: true,
        ),
      );
    }
    if (product.image3d != null && product.image3d!.isNotEmpty) {
      cards.add(
        ProductImagesSlider(
          title: 'dimensionImages',
          images: product.image3d!,
          compact: true,
        ),
      );
    }

    final rawVideo = product.videoUrl?.toString().trim();
    final resolvedVideo =
        rawVideo == null || rawVideo.isEmpty || rawVideo == 'null'
            ? null
            : ShowNetImage.getPhoto(rawVideo);
    if (resolvedVideo != null &&
        resolvedVideo != AssetsManager.noImageNet &&
        resolvedVideo.isNotEmpty) {
      cards.add(_CompactVideoCard(videoUrl: resolvedVideo));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    final visibleCards = expanded ? cards : <Widget>[];

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.perm_media_outlined,
                size: 20.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'productDetailsSectionMedia'.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => expanded = !expanded),
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20.sp,
                ),
                label: Text(expanded ? 'إخفاء' : 'عرض'),
              ),
            ],
          ),
          if (expanded) ...[
            SizedBox(height: 10.h),
            GridView.builder(
              itemCount: visibleCards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) => visibleCards[index],
            ),
          ] else
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                '${cards.length} وسائط',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactVideoCard extends StatelessWidget {
  const _CompactVideoCard({required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 17.sp,
                color: AppColors.secondaryColor,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  'productVideo'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.sp,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13.r),
              child: ProductInlineVideo(videoUrl: videoUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsScreen extends GetView<StockController> {
  const ProductDetailsScreen({Key? key}) : super(key: key);

  Future<void> _openProductQuickAdjust(
    BuildContext context,
    ProductDetailsModel product,
  ) async {
    if (_productHasVariants(product)) {
      final target = await showStockVariantAdjustSheet(
        context: context,
        product: product,
      );
      if (target == null) return;
      final pick = await showStockQuickAdjustSheet(
        context: context,
        title: product.nameAr,
        subtitle: target.subtitle,
        currentStock: target.currentStock,
      );
      if (pick == null) return;
      await controller.adjustProductStock(
        productId: product.id,
        sizeColorId: target.sizeColorId,
        quantity: pick.quantity,
        note: pick.note,
      );
      return;
    }

    final stock = int.tryParse(product.stock?.toString() ?? '0') ?? 0;
    final pick = await showStockQuickAdjustSheet(
      context: context,
      title: product.nameAr,
      currentStock: stock,
    );
    if (pick == null) return;
    await controller.adjustProductStock(
      productId: product.id,
      quantity: pick.quantity,
      note: pick.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: CustomAppBar(
        title: 'productDetails',
        action: false,
        actions: [
          Obx(() {
            final product = controller.productDetails.value;
            if (product == null) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'addStockQuick'.tr,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _openProductQuickAdjust(context, product),
            );
          }),
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
                  child: SingleChildScrollView(
                    child: ProductDetailsPageSkeleton(),
                  ),
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
                      SizedBox(height: 6.h),
                      _ProductDetailsHero(product: product),
                      SizedBox(height: 8.h),
                      _ProductOverviewGrid(product: product),
                      SizedBox(height: 12.h),
                      _SizeColorDetailsTable(product: product),
                      SizedBox(height: 12.h),
                      ProductStockMovementsLink(
                        productId: product.id,
                        productName: product.nameAr,
                        currentStock:
                            int.tryParse(product.stock?.toString() ?? '0') ?? 0,
                        hasVariants: _productHasVariants(product),
                      ),
                      SizedBox(height: 12.h),
                      _ProductMediaSection(product: product),
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

bool _productHasVariants(ProductDetailsModel product) {
  for (final sz in product.sizes ?? <Size>[]) {
    if ((sz.colorSizes ?? []).isNotEmpty) return true;
  }
  return false;
}

class _SizeColorDetailsTable extends StatefulWidget {
  const _SizeColorDetailsTable({required this.product});

  final ProductDetailsModel product;

  @override
  State<_SizeColorDetailsTable> createState() => _SizeColorDetailsTableState();
}

class _SizeColorDetailsTableState extends State<_SizeColorDetailsTable> {
  bool expanded = false;

  StockController get _stock => Get.find<StockController>();

  Future<void> _openQuickAdjust(
    BuildContext context, {
    required String size,
    required ColorSize color,
  }) async {
    final pick = await showStockQuickAdjustSheet(
      context: context,
      title: widget.product.nameAr,
      subtitle: '$size / ${color.colorAr ?? '—'}',
      currentStock: int.tryParse(color.stock ?? '0') ?? 0,
    );
    if (pick == null) return;
    await _stock.adjustProductStock(
      productId: widget.product.id,
      sizeColorId: color.id,
      quantity: pick.quantity,
      note: pick.note,
    );
  }

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
    final product = widget.product;
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
      return ProductCollapsibleSection(
        icon: Icons.straighten,
        title: 'productDetailsSectionSizes'.tr,
        countText: '0',
        expanded: false,
        onToggle: null,
        child: Text(
          'noData'.tr,
          textAlign: TextAlign.center,
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

    return ProductCollapsibleSection(
      icon: Icons.straighten,
      title: 'productDetailsSectionSizes'.tr,
      countText: '${grouped.length} / ${rows.length}',
      expanded: expanded,
      onToggle: () => setState(() => expanded = !expanded),
      child: Column(
        children: grouped.entries
            .map(
              (entry) => _SizeColorCard(
                size: entry.key,
                colors: entry.value,
                onTranslate: (color) => _showColorLanguages(context, color),
                onAdjustStock: (color) => _openQuickAdjust(
                  context,
                  size: entry.key,
                  color: color,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SizeColorCard extends StatelessWidget {
  const _SizeColorCard({
    required this.size,
    required this.colors,
    required this.onTranslate,
    required this.onAdjustStock,
  });

  final String size;
  final List<ColorSize> colors;
  final ValueChanged<ColorSize> onTranslate;
  final ValueChanged<ColorSize> onAdjustStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(9.w),
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
                size: 16.sp,
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
          SizedBox(height: 7.h),
          for (final color in colors) ...[
            _ColorSizeLine(
              color: color,
              onTranslate: onTranslate,
              onAdjustStock: () => onAdjustStock(color),
            ),
            if (color != colors.last) SizedBox(height: 6.h),
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
    required this.onAdjustStock,
  });

  final ColorSize color;
  final ValueChanged<ColorSize> onTranslate;
  final VoidCallback onAdjustStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          if (color.imageUrl != null && color.imageUrl!.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Image.network(
                ShowNetImage.getPhoto(color.imageUrl!),
                width: 36.w,
                height: 36.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => SizedBox(width: 36.w, height: 36.w),
              ),
            ),
            SizedBox(width: 8.w),
          ],
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
          ProductMiniStat(label: 'quantity'.tr, value: color.stock ?? '0'),
          ProductMiniStat(label: 'price'.tr, value: color.normailPrice ?? '—'),
          IconButton(
            tooltip: 'addStockQuick'.tr,
            icon: Icon(
              Icons.add_circle_outline,
              size: 18.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onAdjustStock,
          ),
          IconButton(
            tooltip: 'اللغات الاخرى',
            icon: Icon(
              Icons.translate,
              size: 16.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => onTranslate(color),
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
