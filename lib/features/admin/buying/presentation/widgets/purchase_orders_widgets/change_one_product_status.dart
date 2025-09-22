import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/purchase_orders_controller.dart';

class ChangeOneProductStatus extends StatelessWidget {
  const ChangeOneProductStatus({
    Key? key,
    required this.billId,
    required this.productId,
  }) : super(key: key);

  final String billId;
  final String productId;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 10.h,
        ),
        child: GetBuilder<PurchaseOrdersController>(
          builder: (controller) {
            return Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomCheckBox(
                    title: 'purchase'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                    value: controller.purchase,
                    onChanged: (val) => controller.setOnlyOneTrue('purchase'),
                  ),
                  CustomCheckBox(
                    title: 'deliver_product'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                    value: controller.deliverProduct,
                    onChanged: (val) =>
                        controller.setOnlyOneTrue('deliverProduct'),
                  ),
                  CustomCheckBox(
                    title: 'purchase_new_price'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                    value: controller.purchaseNewPrice,
                    onChanged: (val) =>
                        controller.setOnlyOneTrue('purchaseNewPrice'),
                  ),
                  if (controller.purchaseNewPrice.value)
                    CustomTextField(
                      label: '',
                      hintText: 'purchase_new_price',
                      controller: controller.purchaseNewPriceController,
                      keyboardType: TextInputType.number,
                    ),
                  SizedBox(height: 20.h),
                  AppButton(
                    isLoading: controller.isLoading2,
                    isSafeArea: false,
                    text: 'reviewed'.tr,
                    onPressed: () => controller.changeOneStatus(
                      context: context,
                      productId: productId,
                      billId: billId,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
