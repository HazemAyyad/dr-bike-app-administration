import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';

class EditProductScreen extends GetView<StockController> {
  const EditProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'editProduct',
        action: false,
        // actions: [],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            CustomTextField(
              label: 'productName',
              hintText: 'productName',
              controller: controller.productNameController,
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              label: 'productDetails',
              hintText: 'productDetails',
              controller: controller.productDetailsController,
            ),
            SizedBox(height: 10.h),
            CustomDropdownField(
              label: 'subCategory',
              hint: 'subCategory',
              dropdownField: controller.categories
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.id.toString(),
                      child: Text(e.nameAr),
                    ),
                  )
                  .toList(),
              value: controller.categories
                  .where((element) =>
                      element.id ==
                      (controller.subCategoryController.text.isEmpty
                          ? '1'
                          : controller.subCategoryController.text))
                  .first
                  .id,
              onChanged: (val) {
                controller.subCategoryController.text = val!;
              },
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Flexible(
                  child: CustomTextField(
                    enabled: false,
                    label: 'stock',
                    hintText: 'stock',
                    controller: controller.stockController,
                  ),
                ),
                SizedBox(width: 10.h),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        'wholesalePrices'.tr,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.customGreyColor,
                            ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.file_copy,
                          color: AppColors.primaryColor,
                          size: 25.sp,
                        ),
                        onPressed: () {
                          // Get.dialog(
                          //   ShowWholesalePrices(product: product),
                          // );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.h),
                Flexible(
                  child: CustomTextField(
                    label: 'retailPrice',
                    hintText: 'retailPrice',
                    controller: controller.retailPricesController,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: CustomTextField(
                    label: 'discountPercentage',
                    hintText: 'discountPercentage',
                    controller: controller.discountPercentageController,
                  ),
                ),
                SizedBox(width: 10.h),
                Flexible(
                  child: CustomDropdownField(
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
                      // value: controller.projects
                      //     .where((element) =>
                      //         element.id ==
                      //         controller.selectPurchaseController.text)
                      //     .first
                      //     .id,
                      onChanged: (val) {
                        controller.selectPurchaseController.text = val!;
                      }),
                ),
              ],
            ),
            GetBuilder<StockController>(
              builder: (controller) {
                return Column(
                  children: [
                    ...controller.items.map(
                      (i) {
                        return Column(
                          children: [
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (controller.items.length > 1)
                                  IconButton(
                                    onPressed: () {
                                      controller.removeItem(
                                        controller.items.indexOf(i),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      size: 30.sp,
                                      color: AppColors.redColor,
                                    ),
                                  ),
                                Flexible(
                                  child: CustomTextField(
                                    label: 'size',
                                    hintText: 'size',
                                    controller: i.sizeController,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    controller.addSized();
                                  },
                                  icon: Icon(
                                    Icons.add_circle_outlined,
                                    size: 40.sp,
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            ...i.colors.map(
                              (c) {
                                return Column(
                                  children: [
                                    SizedBox(height: 3.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (i.colors.length > 1)
                                          IconButton(
                                            onPressed: () {
                                              controller.removeColorFromSize(
                                                controller.items.indexOf(i),
                                                i.colors.indexOf(c),
                                              );
                                            },
                                            icon: Icon(
                                              Icons.delete,
                                              size: 30.sp,
                                              color: AppColors.redColor,
                                            ),
                                          ),
                                        Flexible(
                                          child: CustomTextField(
                                            label: 'color',
                                            hintText: 'color',
                                            controller: c.colorController,
                                          ),
                                        ),
                                        SizedBox(width: 10.h),
                                        Flexible(
                                          child: CustomTextField(
                                            label: 'quantity',
                                            hintText: 'quantity',
                                            controller: c.quantityController,
                                          ),
                                        ),
                                        SizedBox(width: 10.h),
                                        Flexible(
                                          child: CustomTextField(
                                            label: 'price',
                                            hintText: 'price',
                                            controller: c.priceController,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            controller.addColorToSize(
                                              controller.items.indexOf(i),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.add_circle_outlined,
                                            size: 40.sp,
                                            color: AppColors.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 15.h),
            Row(
              children: [
                Text(
                  'productRotationDate'.tr,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
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
            SizedBox(height: 20.h),
            CustomTextField(
              label: 'purchasePrice',
              hintText: 'purchasePrice',
              controller: controller.purchasePriceController,
            ),
            SizedBox(height: 10.h),
            CustomCheckBox(
              title: 'isForcedSale',
              value: controller.isForcedSale,
              onChanged: (value) {
                controller.isForcedSale.value = value!;
              },
            ),
            SizedBox(height: 10.h),
            AppButton(
              text: 'editProduct',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
