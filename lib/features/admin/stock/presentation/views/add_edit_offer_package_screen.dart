import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/offer_packages_controller.dart';
import '../widgets/offer_package_product_tile.dart';

class AddEditOfferPackageScreen extends GetView<OfferPackagesController> {
  const AddEditOfferPackageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final footerBg = ThemeService.isDark.value
        ? AppColors.customGreyColor
        : AppColors.whiteColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: controller.editingPackageId.value != null
            ? 'editOfferPackage'
            : 'addOfferPackage',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'packageName',
              hintText: 'packageName',
              controller: controller.nameController,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'unitPackagePrice',
                    hintText: 'price',
                    controller: controller.priceController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                        child: CustomTextField(
                          label: 'packageDefinitionQty',
                          hintText: '1',
                          controller: controller.packageQuantityController,
                          keyboardType: TextInputType.number,
                        ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'packageImage'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
            ),
            SizedBox(height: 8.h),
            Obx(() {
              final file = controller.pendingImage.value;
              final url = controller.existingImageUrl;
              return GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  height: 110.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.customGreyColor3),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  alignment: Alignment.center,
                  child: file != null
                      ? Image.file(
                          File(file.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                            : url != null &&
                                    url.isNotEmpty &&
                                    url.toLowerCase() != 'no image'
                                ? CachedNetworkImage(
                                    imageUrl: ShowNetImage.getPhoto(url),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.customGreyColor2,
                                    ),
                                  )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 28.sp,
                                  color: AppColors.customGreyColor2,
                                ),
                                Text(
                                  'tapToAddImage'.tr,
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                ),
              );
            }),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'packageProducts'.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textColor,
                      ),
                ),
                TextButton.icon(
                  onPressed: controller.openAddProductDialog,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: textColor,
                    size: 22.sp,
                  ),
                  label: Text(
                    'addProduct'.tr,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Obx(() {
              if (controller.packageProducts.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor4
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Center(
                    child: Text(
                      'addProductsViaButton'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textColor,
                          ),
                    ),
                  ),
                );
              }
              return Column(
                children: List.generate(
                  controller.packageProducts.length,
                  (index) {
                    final row = controller.packageProducts[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor4
                              : AppColors.whiteColor2,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: OfferPackageProductTile(
                          row: row,
                          index: index,
                          onEdit: () => controller.editProductAt(index),
                          onDelete: () =>
                              controller.removeProductFromTable(index),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            SizedBox(height: 120.h),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: footerBg,
          border: Border(
            top: BorderSide(color: AppColors.customGreyColor3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () => Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor4
                          : AppColors.whiteColor2,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.customGreyColor3),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'partsRealTotalPrice'.tr,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                        Text(
                          controller.partsRealTotal.toStringAsFixed(2),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                AppButton(
                  isLoading: controller.isSubmitting,
                  text: 'save'.tr,
                  isSafeArea: false,
                  onPressed: () => controller.submitPackage(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
