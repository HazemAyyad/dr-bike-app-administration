import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../sales/data/models/product_model.dart';
import '../../data/models/product_details_model.dart' show ProductMediaItem;
import '../controllers/stock_controller.dart';
import '../widgets/product_inline_video.dart';

/// عناوين الأقسام: على الخلفية الداكنة لا يُستخدم [AppColors.secondaryColor] لأنه شبه أسود ويختفي.
Color editProductSectionTitleColor(BuildContext context) {
  final t = Theme.of(context);
  if (t.brightness == Brightness.dark) {
    return t.colorScheme.primary;
  }
  return AppColors.secondaryColor;
}

class EditProductScreen extends GetView<StockController> {
  const EditProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.4),
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
              Text(
                'sectionProductNames'.tr,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: editProductSectionTitleColor(context),
                    ),
              ),
              SizedBox(height: 8.h),
              CustomTextField(
                label: 'productName',
                hintText: 'productName',
                controller: controller.productNameController,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'nameEnglish',
                hintText: 'nameEnglish',
                controller: controller.nameEngController,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'nameHebrew',
                hintText: 'nameHebrew',
                controller: controller.nameAbreeController,
              ),
              SizedBox(height: 16.h),
              Text(
                'sectionDescriptions'.tr,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: editProductSectionTitleColor(context),
                    ),
              ),
              SizedBox(height: 8.h),
              CustomTextField(
                label: 'productDetails',
                hintText: 'productDetails',
                controller: controller.productDetailsController,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'descriptionEnglish',
                hintText: 'descriptionEnglish',
                controller: controller.descriptionEngController,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'descriptionHebrew',
                hintText: 'descriptionHebrew',
                controller: controller.descriptionAbreeController,
              ),
              SizedBox(height: 16.h),
              Text(
                'subCategoryMulti'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: editProductSectionTitleColor(context),
                    ),
              ),
              SizedBox(height: 8.h),
              Obx(
                () {
                  final ids = controller.selectedSubCategoryIds.toList();
                  final selected = controller.categories
                      .where((c) => ids.contains(c.id))
                      .toList();
                  if (controller.categories.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text('noCategories'.tr),
                    );
                  }
                  return DropdownSearch<ProductModel>.multiSelection(
                    key: ValueKey(ids.join(',')),
                    selectedItems: selected,
                    items: (filter, loadProps) async => controller.categories,
                    itemAsString: (c) => c.nameAr,
                    compareFn: (a, b) => a.id == b.id,
                    popupProps: PopupPropsMultiSelection.menu(
                      showSearchBox: true,
                      constraints: const BoxConstraints(maxHeight: 320),
                      // إخفاء زر OK — التحديث فوري عبر onItemAdded / onItemRemoved
                      validationBuilder: (_, __) => const SizedBox.shrink(),
                      onItemAdded: (selectedItems, _) {
                        controller.selectedSubCategoryIds.clear();
                        controller.selectedSubCategoryIds
                            .addAll(selectedItems.map((e) => e.id));
                        controller.update();
                      },
                      onItemRemoved: (selectedItems, _) {
                        controller.selectedSubCategoryIds.clear();
                        controller.selectedSubCategoryIds
                            .addAll(selectedItems.map((e) => e.id));
                        controller.update();
                      },
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.whiteColor2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        labelText: 'subCategorySelect2Hint'.tr,
                        hintText: 'subCategorySelect2Hint'.tr,
                      ),
                    ),
                    onChanged: (list) {
                      controller.selectedSubCategoryIds.clear();
                      controller.selectedSubCategoryIds
                          .addAll(list.map((e) => e.id));
                      controller.update();
                    },
                  );
                },
              ),
              SizedBox(height: 16.h),
              Text(
                'sectionPricingStock'.tr,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: editProductSectionTitleColor(context),
                    ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      enabled: controller.editingProductId.value == null,
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
              SizedBox(height: 10.h),
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
              SizedBox(height: 14.h),
              Text(
                'extraLaravelFields'.tr,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: editProductSectionTitleColor(context)
                          .withValues(alpha: 0.95),
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
              SizedBox(height: 10.h),
              _rotationDateField(context),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      label: 'discountPercentage',
                      hintText: 'discountPercentage',
                      controller: controller.discountPercentageController,
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
              SizedBox(height: 10.h),
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
              SizedBox(height: 10.h),
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
              SizedBox(height: 12.h),
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
              SizedBox(height: 16.h),
              Text(
                'sectionSizeColor'.tr,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: editProductSectionTitleColor(context),
                    ),
              ),
              SizedBox(height: 8.h),
              GetBuilder<StockController>(
                builder: (c) {
                  if (c.items.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: OutlinedButton.icon(
                        onPressed: c.addSized,
                        icon: Icon(Icons.add, size: 22.sp),
                        label: Text('addSizeColorSection'.tr),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'addSizeBlock'.tr,
                            onPressed: c.addSized,
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 28.sp,
                              color: AppColors.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text(
                          'colorsAndQtySubtitle'.tr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                        ),
                      ),
                      ...c.items.map(
                        (i) {
                          final blockIndex = c.items.indexOf(i);
                          final opts = List<String>.from(c.productSizeOptions);
                          final cur = i.sizeController.text.trim();
                          if (cur.isNotEmpty && !opts.contains(cur)) {
                            opts.insert(0, cur);
                          }
                          return Card(
                            margin: EdgeInsets.only(bottom: 12.h),
                            elevation: 1,
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          hint: Text('sizeSelectHint'.tr),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppColors.whiteColor2,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(11.r),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 14.w,
                                              vertical: 12.h,
                                            ),
                                            labelText: 'size'.tr,
                                          ),
                                          value: cur.isEmpty
                                              ? null
                                              : (opts.contains(cur) ? cur : null),
                                          items: opts
                                              .map(
                                                (s) => DropdownMenuItem<String>(
                                                  value: s,
                                                  child: Text(s),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            i.sizeController.text = v ?? '';
                                            c.update();
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          c.removeItem(blockIndex);
                                        },
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 26.sp,
                                          color: AppColors.redColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'colorAndQuantityHeading'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  SizedBox(height: 6.h),
                                  ...i.colors.map(
                                    (col) {
                                      return Column(
                                        children: [
                                          SizedBox(height: 6.h),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: CustomTextField(
                                                  label: 'color',
                                                  hintText: 'color',
                                                  controller:
                                                      col.colorController,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: CustomTextField(
                                                  label: 'colorEnglish',
                                                  hintText: 'colorEnglish',
                                                  controller:
                                                      col.colorEnController,
                                                ),
                                              ),
                                              if (i.colors.length > 1)
                                                IconButton(
                                                  onPressed: () {
                                                    c.removeColorFromSize(
                                                      blockIndex,
                                                      i.colors.indexOf(col),
                                                    );
                                                  },
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    size: 24.sp,
                                                    color: AppColors.redColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 6.h),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomTextField(
                                                  label: 'colorHebrew',
                                                  hintText: 'colorHebrew',
                                                  controller:
                                                      col.colorAbbrController,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: CustomTextField(
                                                  label: 'quantity',
                                                  hintText: 'quantity',
                                                  controller:
                                                      col.quantityController,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: CustomTextField(
                                                  label: 'price',
                                                  hintText: 'price',
                                                  controller:
                                                      col.priceController,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  c.addColorToSize(
                                                    blockIndex,
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.add_circle_outline,
                                                  size: 32.sp,
                                                  color: AppColors
                                                      .secondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
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
                        SizedBox(height: 10.h),
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
                        onPick: c.pickNormalImages,
                        onRemoveExisting: c.confirmRemoveExistingNormal,
                        onRemovePending: c.removePendingNormalAt,
                      ),
                      SizedBox(height: 10.h),
                      _mediaTypeStrip(
                        context,
                        c,
                        title: 'viewImagesLabel'.tr,
                        uploadHint: 'uploadMediaHere'.tr,
                        existing: c.existingViewMedia,
                        pending: c.pendingViewImages,
                        onPick: c.pickViewImages,
                        onRemoveExisting: c.confirmRemoveExistingView,
                        onRemovePending: c.removePendingViewAt,
                      ),
                      SizedBox(height: 10.h),
                      _mediaTypeStrip(
                        context,
                        c,
                        title: 'threeDImagesLabel'.tr,
                        uploadHint: 'uploadMediaHere'.tr,
                        existing: c.existingThreeDMedia,
                        pending: c.pendingThreeDImages,
                        onPick: c.pickThreeDImages,
                        onRemoveExisting: c.confirmRemoveExistingThreeD,
                        onRemovePending: c.removePendingThreeDAt,
                      ),
                      SizedBox(height: 10.h),
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
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'delete'.tr,
                                  onPressed: c.confirmRemoveExistingVideo,
                                  icon: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                      ],
                      if (c.pendingVideo != null) ...[
                        Row(
                          children: [
                            Icon(Icons.video_file,
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
                            await c.pickProductVideo();
                            c.update();
                          },
                          icon: Icon(Icons.add_circle_outline,
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
              SizedBox(height: 10.h),
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
            fontSize: 15.sp,
            color: AppColors.customGreyColor,
            fontWeight: FontWeight.w400,
          ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.whiteColor2,
        labelText: 'rotationDateField'.tr,
        labelStyle: TextStyle(
          color: editProductSectionTitleColor(context),
          fontWeight: FontWeight.w500,
        ),
        hintText: 'rotationDateHint'.tr,
        hintStyle: TextStyle(color: AppColors.customGreyColor6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        suffixIcon: Icon(
          Icons.calendar_month_outlined,
          size: 22.sp,
          color: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
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
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onRemoveExisting(item),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
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
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onRemovePending(idx),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
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
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.14),
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
