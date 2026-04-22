import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/product_details_model.dart' show ProductMediaItem;
import '../controllers/stock_controller.dart';
import '../widgets/category_selector_section.dart';
import '../widgets/product_inline_video.dart';
import '../widgets/product_language_tabs_edit.dart';
import '../widgets/size_color_entry_dialog.dart';

/// عناوين الأقسام: على الخلفية الداكنة لا يُستخدم [AppColors.secondaryColor] لأنه شبه أسود ويختفي.
Color editProductSectionTitleColor(BuildContext context) {
  final t = Theme.of(context);
  if (t.brightness == Brightness.dark) {
    return t.colorScheme.primary;
  }
  return AppColors.secondaryColor;
}

Future<void> _pickWithUnfocus(Future<void> Function() pick) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await pick();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  FocusManager.instance.primaryFocus?.unfocus();
}

class EditProductScreen extends GetView<StockController> {
  const EditProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(
          () => CustomAppBar(
            title: controller.editingProductId.value == null
                ? 'addProduct'
                : 'editProduct',
            action: false,
          ),
        ),
      ),
      body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditProductSectionCard(
                titleKey: 'sectionProductContent',
                child: ProductLanguageTabsEdit(controller: controller),
              ),
              EditProductSectionCard(
                titleKey: 'sectionCategories',
                child: CategorySelectorSection(controller: controller),
              ),
              EditProductSectionCard(
                titleKey: 'sectionPricingStock',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            enabled:
                                controller.editingProductId.value == null,
                            label: 'stock',
                            hintText: 'stock',
                            controller: controller.stockController,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            label: 'minimumStock',
                            hintText: 'minimumStock',
                            controller: controller.minimumStockController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            label: 'wholesalePriceField',
                            hintText: 'wholesalePriceField',
                            controller: controller.wholesalePricesController,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            label: 'retailPrice',
                            hintText: 'retailPrice',
                            controller: controller.retailPricesController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'extraLaravelFields'.tr,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: editProductSectionTitleColor(context),
                          ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            label: 'minSalePriceField',
                            hintText: 'minSalePriceField',
                            controller: controller.minSalePriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            label: 'listPriceField',
                            hintText: 'listPriceField',
                            controller: controller.listPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _rotationDateField(context),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            label: 'discountPercentage',
                            hintText: 'discountPercentage',
                            controller:
                                controller.discountPercentageController,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            label: 'manufactureYear',
                            hintText: 'manufactureYear',
                            controller: controller.manufactureYearController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            label: 'productModel',
                            hintText: 'productModel',
                            controller: controller.modelController,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            label: 'rateLabel',
                            hintText: 'rateLabel',
                            controller: controller.rateController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    CustomDropdownField(
                      label: 'selectPurchase',
                      hint: 'selectPurchase',
                      dropdownField: controller.projects
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id.toString(),
                              child: Text(e.nameAr),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        controller.selectPurchaseController.text = val!;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: CustomCheckBox(
                            title: 'productVisible',
                            value: controller.isShowProduct,
                            onChanged: (value) {
                              controller.isShowProduct.value = value!;
                            },
                          ),
                        ),
                        Expanded(
                          child: CustomCheckBox(
                            title: 'productNewBadge',
                            value: controller.isNewItemProduct,
                            onChanged: (value) {
                              controller.isNewItemProduct.value = value!;
                            },
                          ),
                        ),
                      ],
                    ),
                    CustomCheckBox(
                      title: 'productBestSeller',
                      value: controller.isMoreSalesProduct,
                      onChanged: (value) {
                        controller.isMoreSalesProduct.value = value!;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'sectionSizeColor'.tr,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: editProductSectionTitleColor(context),
                    ),
              ),
              SizedBox(height: 8.h),
              _SizeColorSection(controller: controller),
              SizedBox(height: 8.h),
              GetBuilder<StockController>(
                builder: (c) => Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'productMediaSection'.tr,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: editProductSectionTitleColor(context),
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'videoFormatsHint'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                      if (c.editingProductId.value != null) ...[
                        SizedBox(height: 16.h),
                        Text(
                          'existingMediaHeading'.tr,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      _mediaTypeStrip(
                        context,
                        c,
                        title: 'normalImages'.tr,
                        uploadHint: 'uploadMediaHere'.tr,
                        existing: c.existingNormalMedia,
                        pending: c.pendingNormalImages,
                        onPick: () => _pickWithUnfocus(c.pickNormalImages),
                        onRemoveExisting: c.confirmRemoveExistingNormal,
                        onRemovePending: c.removePendingNormalAt,
                      ),
                      SizedBox(height: 16.h),
                      _mediaTypeStrip(
                        context,
                        c,
                        title: 'viewImagesLabel'.tr,
                        uploadHint: 'uploadMediaHere'.tr,
                        existing: c.existingViewMedia,
                        pending: c.pendingViewImages,
                        onPick: () => _pickWithUnfocus(c.pickViewImages),
                        onRemoveExisting: c.confirmRemoveExistingView,
                        onRemovePending: c.removePendingViewAt,
                      ),
                      SizedBox(height: 16.h),
                      _mediaTypeStrip(
                        context,
                        c,
                        title: 'threeDImagesLabel'.tr,
                        uploadHint: 'uploadMediaHere'.tr,
                        existing: c.existingThreeDMedia,
                        pending: c.pendingThreeDImages,
                        onPick: () => _pickWithUnfocus(c.pickThreeDImages),
                        onRemoveExisting: c.confirmRemoveExistingThreeD,
                        onRemovePending: c.removePendingThreeDAt,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'productVideo'.tr,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      SizedBox(height: 6.h),
                      if (c.existingVideoUrlForEdit != null &&
                          c.existingVideoUrlForEdit!.isNotEmpty &&
                          !c.pendingDeleteExistingVideo.value) ...[
                        Text(
                          'existingVideoHeading'.tr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 6.h),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: ProductInlineVideo(
                                videoUrl: ShowNetImage.getPhoto(
                                  c.existingVideoUrlForEdit,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: AdminUiColors.subtleOverlay(context),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'delete'.tr,
                                  onPressed: c.confirmRemoveExistingVideo,
                                  icon: Icon(
                                    Icons.close,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                      ],
                      if (c.pendingVideo != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.video_file,
                                color: AppColors.secondaryColor),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                c.pendingVideo!.name,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                c.pendingVideo = null;
                                c.update();
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                      ],
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () async {
                            await _pickWithUnfocus(c.pickProductVideo);
                            c.update();
                          },
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.secondaryColor),
                          label: Text('pickVideo'.tr),
                        ),
                      ),
                      if (c.pendingNormalImages.isNotEmpty ||
                          c.pendingViewImages.isNotEmpty ||
                          c.pendingThreeDImages.isNotEmpty ||
                          c.pendingVideo != null)
                        TextButton(
                          onPressed: c.clearPendingMedia,
                          child: Text('clearPendingMedia'.tr),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              CustomCheckBox(
                title: 'isForcedSale',
                value: controller.isForcedSale,
                onChanged: (value) {
                  controller.isForcedSale.value = value!;
                },
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.phone_android_outlined,
                      size: 22.sp,
                      color: AppColors.secondaryColor,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'saveScopeLockedHint'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => AppButton(
                  text: controller.editingProductId.value == null
                      ? 'addProduct'
                      : 'editProduct',
                  onPressed: controller.submitProduct,
                  isLoading: controller.isSubmittingProduct,
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
    );
  }

  Widget _rotationDateField(BuildContext context) {
    return TextField(
      controller: controller.rotationDateController,
      readOnly: true,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
      decoration: OutlineInputStyle.merge(
        context,
        labelText: 'rotationDateField'.tr,
        hintText: 'rotationDateHint'.tr,
        suffixIcon: Icon(
          Icons.calendar_month_outlined,
          size: 22.sp,
          color: Theme.of(context).colorScheme.primary,
        ),
      ).copyWith(
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 16.sp,
        ),
      ),
      onTap: () async {
        final now = DateTime.now();
        final t = controller.rotationDateController.text.trim();
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
          controller.rotationDateController.text =
              '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';
          controller.update();
        }
      },
    );
  }

  Widget _resolvedImageThumb(String? rawUrl, double side) {
    final resolved = ShowNetImage.getPhoto(rawUrl);
    if (resolved.startsWith('http')) {
      return CachedNetworkImage(
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
      );
    }
    return Image.asset(
      resolved,
      width: side,
      height: side,
      fit: BoxFit.cover,
    );
  }

  Widget _mediaTypeStrip(
    BuildContext context,
    StockController c, {
    required String title,
    required String uploadHint,
    required RxList<ProductMediaItem> existing,
    required List<XFile> pending,
    required Future<void> Function() onPick,
    required Future<void> Function(ProductMediaItem) onRemoveExisting,
    required void Function(int index) onRemovePending,
  }) {
    final side = 92.w;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              style: BorderStyle.solid,
            ),
            color: AdminUiColors.inputFill(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existing.isEmpty &&
                  pending.isEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    uploadHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...existing.map((item) {
                    final url = item.url;
                    if (url == null || url.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: _resolvedImageThumb(url, side),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Material(
                            color: AdminUiColors.subtleOverlay(context),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onRemoveExisting(item),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  ...pending.asMap().entries.map((e) {
                    final idx = e.key;
                    final f = e.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            File(f.path),
                            width: side,
                            height: side,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Material(
                            color: AdminUiColors.subtleOverlay(context),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onRemovePending(idx),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  Material(
                    color: AdminUiColors.mediaAddTileBackground(context),
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      onTap: () async {
                        await onPick();
                        c.update();
                      },
                      borderRadius: BorderRadius.circular(10.r),
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32.sp,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Size & Color — modal + table
// ═══════════════════════════════════════════════════════════════════════════════

class _SizeColorSection extends StatelessWidget {
  const _SizeColorSection({required this.controller});

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StockController>(
      builder: (c) {
        final rows = c.flatSizeColorEntries;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── add button ──────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => SizeColorEntryDialog.show(c),
              icon: Icon(Icons.add, size: 20.sp),
              label: Text('addSizeColor'.tr),
            ),
            if (rows.isNotEmpty) ...[
              SizedBox(height: 12.h),
              // ── horizontal scrollable table ─────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36.h,
                  dataRowMinHeight: 40.h,
                  dataRowMaxHeight: 52.h,
                  columnSpacing: 14.w,
                  horizontalMargin: 8.w,
                  columns: [
                    DataColumn(label: Text('size'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('color'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('colorEnglish'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('colorHebrew'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('quantity'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('price'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('wholesalePriceField'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('discountPercentage'.tr, style: _headerStyle(context))),
                    DataColumn(label: Text('actions'.tr, style: _headerStyle(context))),
                  ],
                  rows: rows.map<DataRow>((entry) {
                    final col = entry.color;
                    return DataRow(cells: [
                      DataCell(Text(entry.size, style: _cellStyle(context))),
                      DataCell(Text(col.colorController.text, style: _cellStyle(context))),
                      DataCell(Text(col.colorEnController.text, style: _cellStyle(context))),
                      DataCell(Text(col.colorAbbrController.text, style: _cellStyle(context))),
                      DataCell(Text(col.quantityController.text, style: _cellStyle(context))),
                      DataCell(Text(col.priceController.text, style: _cellStyle(context))),
                      DataCell(Text(col.wholesalePriceController.text, style: _cellStyle(context))),
                      DataCell(Text(col.discountController.text, style: _cellStyle(context))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => SizeColorEntryDialog.show(
                              c,
                              sizeIdx: entry.sizeIdx,
                              colorIdx: entry.colorIdx,
                            ),
                            child: Icon(Icons.edit_outlined,
                                size: 18.sp, color: AppColors.primaryColor),
                          ),
                          SizedBox(width: 10.w),
                          InkWell(
                            onTap: () => c.removeSizeColorEntry(
                                entry.sizeIdx, entry.colorIdx),
                            child: Icon(Icons.delete_outline,
                                size: 18.sp, color: AppColors.redColor),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  TextStyle _headerStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10.sp,
          );

  TextStyle _cellStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11.sp);
}
