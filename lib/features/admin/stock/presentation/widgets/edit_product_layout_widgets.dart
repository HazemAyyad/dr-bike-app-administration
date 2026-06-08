import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/product_details_model.dart' show ProductMediaItem;
import '../controllers/stock_controller.dart';
import 'category_selector_section.dart';
import 'product_inline_video.dart';
import 'product_language_tabs_edit.dart';
import 'product_location_badge.dart';
import 'product_screen_shared_widgets.dart';
import 'size_color_entry_dialog.dart';

Future<void> pickWithUnfocus(Future<void> Function() pick) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await pick();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  FocusManager.instance.primaryFocus?.unfocus();
}

/// Hero card: languages, categories, tags — mirrors product details header.
class EditProductHero extends StatelessWidget {
  const EditProductHero({Key? key, required this.controller}) : super(key: key);

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    return ProductHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductArabicFieldsEdit(controller: controller),
          SizedBox(height: 10.h),
          Obx(() {
            final chips = <Widget>[];
            if (controller.editingProductId.value != null) {
              final p = controller.productDetails.value;
              final sectionName = controller.selectedProductSectionName ??
                  p?.storeSectionName;
              final shelf = controller.editProductShelfNumber.value.trim().isNotEmpty
                  ? controller.editProductShelfNumber.value.trim()
                  : (p?.shelfNumber?.trim() ?? '');
              final locationCodeLabel = ProductLocationLabel.withProductCode(
                sectionName: sectionName,
                shelfNumber: shelf.isEmpty ? null : shelf,
                productCode: p?.productCode,
              );
              if (locationCodeLabel != null && locationCodeLabel.isNotEmpty) {
                chips.add(
                  ProductMetaChip(
                    icon: Icons.qr_code_2,
                    text: locationCodeLabel,
                  ),
                );
              }
            }
            final mainId = controller.selectedMainCategoryId.value;
            if (mainId != null && mainId.isNotEmpty) {
              final main = controller.mainCategories
                  .where((m) => m.id.trim() == mainId.trim())
                  .toList();
              if (main.isNotEmpty) {
                chips.add(
                  ProductMetaChip(
                    icon: Icons.account_tree_outlined,
                    text: main.first.nameAr,
                  ),
                );
              }
            }
            final subIds = controller.selectedSubCategoryIds.toList();
            final filtered = controller.getFilteredSubCategories();
            for (final id in subIds) {
              final sub = filtered.where((s) => s.id == id).toList();
              if (sub.isNotEmpty) {
                chips.add(
                  ProductMetaChip(
                    icon: Icons.label_outline,
                    text: sub.first.nameAr,
                  ),
                );
              }
            }
            if (chips.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: chips,
            );
          }),
          SizedBox(height: 12.h),
          CategorySelectorSection(controller: controller),
        ],
      ),
    );
  }
}

class EditMetricInputCard extends StatelessWidget {
  const EditMetricInputCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      readOnly: readOnly || onTap != null,
      onTap: onTap,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 12.sp,
          ),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: '—',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 12.sp,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
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
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 15.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                field,
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.calendar_month_outlined,
              size: 14.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

class EditProductOverviewSection extends StatefulWidget {
  const EditProductOverviewSection({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  @override
  State<EditProductOverviewSection> createState() =>
      _EditProductOverviewSectionState();
}

class _EditProductOverviewSectionState extends State<EditProductOverviewSection> {
  Future<void> _pickRotationDate() async {
    final c = widget.controller;
    final now = DateTime.now();
    final t = c.rotationDateController.text.trim();
    DateTime initial = now;
    if (t.length >= 10) {
      initial = DateTime.tryParse(t.substring(0, 10)) ?? now;
    }
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Get.locale,
    );
    if (d != null) {
      c.rotationDateController.text =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      c.update();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final allFields = <Widget>[
      EditMetricInputCard(
        icon: Icons.inventory_2_outlined,
        label: 'stock'.tr,
        controller: c.stockController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: false,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.warning_amber_rounded,
        label: 'minimumStock'.tr,
        controller: c.minimumStockController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.sell_outlined,
        label: 'retailPrice'.tr,
        controller: c.retailPricesController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.storefront_outlined,
        label: 'wholesalePriceField'.tr,
        controller: c.wholesalePricesController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.shopping_bag_outlined,
        label: 'productCost'.tr,
        controller: c.purchasePriceController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.percent,
        label: 'discountPercentage'.tr,
        controller: c.discountPercentageController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.price_change_outlined,
        label: 'minimumSalePrice'.tr,
        controller: c.minSalePriceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      EditMetricInputCard(
        icon: Icons.price_check_outlined,
        label: 'listPriceField'.tr,
        controller: c.listPriceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      EditMetricInputCard(
        icon: Icons.two_wheeler_outlined,
        label: 'productModel'.tr,
        controller: c.modelController,
      ),
      EditMetricInputCard(
        icon: Icons.calendar_month_outlined,
        label: 'manufactureYear'.tr,
        controller: c.manufactureYearController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: false,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.star_rate_rounded,
        label: 'rateLabel'.tr,
        controller: c.rateController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
      ),
      EditMetricInputCard(
        icon: Icons.update_rounded,
        label: 'rotationDateField'.tr,
        controller: c.rotationDateController,
        readOnly: true,
        onTap: _pickRotationDate,
      ),
    ];

    return GridView.builder(
      itemCount: allFields.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 2.85,
      ),
      itemBuilder: (context, index) => allFields[index],
    );
  }
}

class EditSizeColorSection extends StatefulWidget {
  const EditSizeColorSection({Key? key, required this.controller}) : super(key: key);

  final StockController controller;

  @override
  State<EditSizeColorSection> createState() => _EditSizeColorSectionState();
}

class _EditSizeColorSectionState extends State<EditSizeColorSection> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GetBuilder<StockController>(
      builder: (c) {
        final rows = c.flatSizeColorEntries;
        final grouped = <String, List<SizeColorEntry>>{};
        for (final entry in rows) {
          final key = entry.size.trim().isEmpty ? '—' : entry.size;
          grouped.putIfAbsent(key, () => []).add(entry);
        }

        final countLabel = grouped.isEmpty
            ? '0'
            : '${grouped.length} / ${rows.length}';

        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AdminUiColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.straighten,
                    size: 22.sp,
                    color: cs.primary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'sectionSizeColor'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AdminUiColors.subtleOverlay(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      countLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: FilledButton.icon(
                  onPressed: () => SizeColorEntryDialog.show(c),
                  icon: Icon(Icons.add_rounded, size: 22.sp),
                  label: Text(
                    'addSizeColorSection'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              if (rows.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    'noData'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                )
              else
                ...grouped.entries.map(
                  (e) => _EditSizeColorCard(
                    size: e.key,
                    entries: e.value,
                    controller: c,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EditSizeColorCard extends StatelessWidget {
  const _EditSizeColorCard({
    required this.size,
    required this.entries,
    required this.controller,
  });

  final String size;
  final List<SizeColorEntry> entries;
  final StockController controller;

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
                  '${entries.length} ${'color'.tr}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          for (final entry in entries) ...[
            _EditColorSizeLine(entry: entry, controller: controller),
            if (entry != entries.last) SizedBox(height: 6.h),
          ],
        ],
      ),
    );
  }
}

class _EditColorSizeLine extends StatelessWidget {
  const _EditColorSizeLine({
    required this.entry,
    required this.controller,
  });

  final SizeColorEntry entry;
  final StockController controller;

  @override
  Widget build(BuildContext context) {
    final col = entry.color;
    final name = col.colorController.text.trim();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name.isEmpty ? '—' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          ProductMiniStat(
            label: 'quantity'.tr,
            value: col.quantityController.text,
          ),
          ProductMiniStat(
            label: 'price'.tr,
            value: col.priceController.text,
          ),
          IconButton(
            tooltip: 'edit'.tr,
            icon: Icon(
              Icons.edit_outlined,
              size: 16.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => SizeColorEntryDialog.show(
              controller,
              sizeIdx: entry.sizeIdx,
              colorIdx: entry.colorIdx,
            ),
          ),
          IconButton(
            tooltip: 'delete'.tr,
            icon: Icon(
              Icons.delete_outline,
              size: 16.sp,
              color: AppColors.redColor,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.removeSizeColorEntry(
              entry.sizeIdx,
              entry.colorIdx,
            ),
          ),
        ],
      ),
    );
  }
}

class EditProductMediaSection extends StatelessWidget {
  const EditProductMediaSection({Key? key, required this.controller})
      : super(key: key);

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StockController>(
      builder: (c) {
        final mediaStrips = <Widget>[
          _EditMediaStrip(
            controller: c,
            compact: true,
            title: 'naturalImages'.tr,
            existing: c.existingNormalMedia,
            pending: c.pendingNormalImages,
            onPick: () => pickWithUnfocus(c.pickNormalImages),
            onRemoveExisting: c.confirmRemoveExistingNormal,
            onRemovePending: c.removePendingNormalAt,
          ),
          _EditMediaStrip(
            controller: c,
            compact: true,
            title: 'productImages'.tr,
            existing: c.existingViewMedia,
            pending: c.pendingViewImages,
            onPick: () => pickWithUnfocus(c.pickViewImages),
            onRemoveExisting: c.confirmRemoveExistingView,
            onRemovePending: c.removePendingViewAt,
          ),
          _EditMediaStrip(
            controller: c,
            compact: true,
            title: 'dimensionImages'.tr,
            existing: c.existingThreeDMedia,
            pending: c.pendingThreeDImages,
            onPick: () => pickWithUnfocus(c.pickThreeDImages),
            onRemoveExisting: c.confirmRemoveExistingThreeD,
            onRemovePending: c.removePendingThreeDAt,
          ),
          _EditVideoStrip(controller: c, compact: true, gridCell: true),
        ];

        final cs = Theme.of(context).colorScheme;

        return Container(
          padding: EdgeInsets.all(14.w),
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
                    size: 22.sp,
                    color: cs.primary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'productDetailsSectionMedia'.tr,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'videoFormatsHint'.tr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              SizedBox(height: 12.h),
              GridView.builder(
                itemCount: mediaStrips.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) => mediaStrips[index],
              ),
              if (c.pendingNormalImages.isNotEmpty ||
                  c.pendingViewImages.isNotEmpty ||
                  c.pendingThreeDImages.isNotEmpty ||
                  c.pendingVideo != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: c.clearPendingMedia,
                    child: Text('clearPendingMedia'.tr),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EditMediaStrip extends StatelessWidget {
  const _EditMediaStrip({
    required this.controller,
    required this.title,
    required this.existing,
    required this.pending,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemovePending,
    this.compact = false,
  });

  final StockController controller;
  final bool compact;
  final String title;
  final RxList<ProductMediaItem> existing;
  final List<XFile> pending;
  final Future<void> Function() onPick;
  final Future<void> Function(ProductMediaItem) onRemoveExisting;
  final void Function(int index) onRemovePending;

  @override
  Widget build(BuildContext context) {
    final side = compact ? 56.w : 72.w;
    return Container(
      padding: EdgeInsets.all(compact ? 8.w : 9.w),
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
                Icons.photo_library_outlined,
                size: 17.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  title,
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
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ...existing.map((item) {
                final url = item.url;
                if (url == null || url.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _thumbStack(
                  context,
                  child: _resolvedImageThumb(url, side),
                  onRemove: () => onRemoveExisting(item),
                );
              }),
              ...pending.asMap().entries.map((e) {
                return _thumbStack(
                  context,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(
                      File(e.value.path),
                      width: side,
                      height: side,
                      fit: BoxFit.cover,
                    ),
                  ),
                  onRemove: () => onRemovePending(e.key),
                );
              }),
              Material(
                color: AdminUiColors.mediaAddTileBackground(context),
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  onTap: () async {
                    await onPick();
                    controller.update();
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 28.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumbStack(
    BuildContext context, {
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: AdminUiColors.subtleOverlay(context),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resolvedImageThumb(String? rawUrl, double side) {
    final resolved = ShowNetImage.getPhoto(rawUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: resolved.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: resolved,
              width: side,
              height: side,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: side,
                height: side,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image_outlined),
              ),
            )
          : Image.asset(
              resolved,
              width: side,
              height: side,
              fit: BoxFit.cover,
            ),
    );
  }
}

class _EditVideoStrip extends StatelessWidget {
  const _EditVideoStrip({
    required this.controller,
    this.compact = false,
    this.gridCell = false,
  });

  final StockController controller;
  final bool compact;
  final bool gridCell;

  bool _hasExistingVideo(StockController c) =>
      c.existingVideoUrlForEdit != null &&
      c.existingVideoUrlForEdit!.isNotEmpty &&
      !c.pendingDeleteExistingVideo.value;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(gridCell ? 8.w : 9.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(gridCell ? 18.r : 18.r),
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
          if (gridCell)
            Expanded(child: _gridVideoBody(context, c, cs))
          else ...[
            if (_hasExistingVideo(c)) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13.r),
                    child: SizedBox(
                      height: compact ? 90.h : 120.h,
                      child: ProductInlineVideo(
                        videoUrl:
                            ShowNetImage.getPhoto(c.existingVideoUrlForEdit),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _videoDeleteButton(context, c),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],
            if (c.pendingVideo != null) ...[
              _pendingVideoRow(context, c, compact: compact),
              SizedBox(height: 8.h),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _pickVideo(c),
                icon: const Icon(Icons.add_circle_outline),
                label: Text('pickVideo'.tr),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _gridVideoBody(
    BuildContext context,
    StockController c,
    ColorScheme cs,
  ) {
    if (_hasExistingVideo(c)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: ProductInlineVideo(
              videoUrl: ShowNetImage.getPhoto(c.existingVideoUrlForEdit),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: _videoDeleteButton(context, c, small: true),
          ),
        ],
      );
    }
    if (c.pendingVideo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AdminUiColors.subtleOverlay(context),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.video_file_rounded,
                size: 36.sp,
                color: cs.primary,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          _pendingVideoRow(context, c, compact: true),
        ],
      );
    }
    return Material(
      color: AdminUiColors.mediaAddTileBackground(context),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: () => _pickVideo(c),
        borderRadius: BorderRadius.circular(10.r),
        child: Center(
          child: Icon(
            Icons.video_call_outlined,
            size: 32.sp,
            color: cs.primary,
          ),
        ),
      ),
    );
  }

  Widget _videoDeleteButton(
    BuildContext context,
    StockController c, {
    bool small = false,
  }) {
    return Material(
      color: AdminUiColors.subtleOverlay(context),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'delete'.tr,
        padding: small ? EdgeInsets.all(4.w) : null,
        constraints: small ? const BoxConstraints(minWidth: 28, minHeight: 28) : null,
        onPressed: c.confirmRemoveExistingVideo,
        icon: Icon(
          Icons.close,
          size: small ? 14 : 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _pendingVideoRow(
    BuildContext context,
    StockController c, {
    required bool compact,
  }) {
    return Row(
      children: [
        Icon(
          Icons.video_file,
          size: compact ? 16.sp : 20.sp,
          color: AppColors.secondaryColor,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            c.pendingVideo!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 10.sp : null,
                ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(Icons.delete_outline, size: compact ? 18.sp : 22.sp),
          onPressed: () {
            c.pendingVideo = null;
            c.update();
          },
        ),
      ],
    );
  }

  Future<void> _pickVideo(StockController c) async {
    await pickWithUnfocus(c.pickProductVideo);
    c.update();
  }
}

class EditProductSaveBar extends StatelessWidget {
  const EditProductSaveBar({Key? key, required this.controller}) : super(key: key);

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppButton(
        text: controller.editingProductId.value == null
            ? 'addProduct'
            : 'editProduct',
        onPressed: controller.submitProduct,
        isLoading: controller.isSubmittingProduct,
      ),
    );
  }
}
