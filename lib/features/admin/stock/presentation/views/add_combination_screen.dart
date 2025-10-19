import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import '../widgets/search_widget.dart';

class AddCombinationScreen extends GetView<StockController> {
  const AddCombinationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'newProductComposition',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            const SearchWidget(isCloseouts: true),
            SizedBox(height: 10.h),
            CustomTextField(
              enabled: false,
              label: 'productName',
              hintText: 'productName',
              controller: controller.closeoutsProductNameController,
            ),
            SizedBox(height: 10.h),
            GetBuilder<StockController>(
              builder: (controller) {
                return Column(
                  children: [
                    ...controller.newComposition.map(
                      (i) {
                        return Column(
                          children: [
                            SizedBox(height: 10.h),
                            SearchWidget(
                              isCloseouts: true,
                              borderRadius: BorderRadius.circular(8.r),
                              newComposition: i,
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                if (controller.newComposition.length > 1)
                                  GestureDetector(
                                    onTap: () {
                                      controller.removeComposition(
                                        controller.newComposition.indexOf(i),
                                      );
                                      controller.calculateGrandTotal();
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 20.sp,
                                      color: AppColors.redColor,
                                    ),
                                  ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: CustomTextField(
                                    enabled: false,
                                    label: 'productName',
                                    hintText: 'productName',
                                    controller: i.productNameController,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                SizedBox(
                                  width: 60.w,
                                  child: CustomTextField(
                                    label: 'quantity',
                                    hintText: 'quantity',
                                    controller: i.quantityController,
                                    onChanged: (p0) {
                                      controller.calculateGrandTotal();
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                SizedBox(
                                  width: 80.w,
                                  child: CustomTextField(
                                    enabled: false,
                                    label: 'closeoutsCost',
                                    hintText: 'closeoutsCost',
                                    controller: i.priceController,
                                    onChanged: (p0) {
                                      controller.calculateGrandTotal();
                                    },
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
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    controller.addComposition();
                  },
                  icon: Icon(
                    Icons.add,
                    size: 20.sp,
                    color: AppColors.secondaryColor,
                  ),
                  label: Text(
                    'addProduct'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryColor,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Obx(
              () => CustomTextField(
                enabled: false,
                label: 'productCost',
                hintText: controller.newComposition
                    .map((i) => i.totalPrice)
                    .toString()
                    .replaceAll('(', '')
                    .replaceAll(')', ''),
              ),
            ),
            SizedBox(height: 15.h),
            Obx(
              () => Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      enabled: false,
                      label: 'totalQuantity',
                      hintText: controller.totalQuantity.value.toString(),
                      // controller: ,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      enabled: false,
                      label: 'totalCost',
                      hintText: controller.totalCost.value.toString(),
                      // controller: ,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            AppButton(
              isLoading: controller.isLoading,
              text: 'addCloseout',
              onPressed: () {
                if (controller.closeoutsProductsId.isNotEmpty &&
                    controller.newComposition.isNotEmpty) {
                  controller.toggleAddMenu();
                  controller.addCombination();
                  controller.closeoutsProductsId = '';
                } else {
                  Get.snackbar(
                    'error'.tr,
                    'برجاء اختيار منتج'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(milliseconds: 1500),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
