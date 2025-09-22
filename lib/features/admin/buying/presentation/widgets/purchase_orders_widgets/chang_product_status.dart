import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/purchase_orders_controller.dart';

class ChangProductStatus extends StatelessWidget {
  const ChangProductStatus({
    Key? key,
    required this.productId,
    required this.billId,
  }) : super(key: key);

  final String productId;
  final String billId;
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
                  Text(
                    'product_status'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.redColor,
                        ),
                  ),
                  SizedBox(height: 10.h),
                  CustomCheckBox(
                    title: 'finished'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                    value: controller.finished,
                    onChanged: (val) => controller.setOnlyOneTrue('finished'),
                  ),
                  CustomCheckBox(
                    title: 'missing'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                    value: controller.missing,
                    onChanged: (val) => controller.setOnlyOneTrue('missing'),
                  ),
                  if (controller.missing.value)
                    CustomTextField(
                      label: '',
                      hintText: 'missing',
                      controller: controller.missingController,
                      keyboardType: TextInputType.number,
                    ),
                  CustomCheckBox(
                    title: 'returned_extra'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                    value: controller.returnedExtra,
                    onChanged: (val) =>
                        controller.setOnlyOneTrue('returnedExtra'),
                  ),
                  if (controller.returnedExtra.value)
                    CustomTextField(
                      label: '',
                      hintText: 'returned_extra',
                      controller: controller.returnedExtraController,
                      keyboardType: TextInputType.number,
                    ),
                  CustomCheckBox(
                    title: 'not_compatible'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                    value: controller.notCompatible,
                    onChanged: (val) =>
                        controller.setOnlyOneTrue('notCompatible'),
                  ),
                  if (controller.notCompatible.value)
                    Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            label: '',
                            hintText: 'piecesCount',
                            controller: controller.notCompatibleController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            label: '',
                            hintText: 'reason',
                            controller:
                                controller.notCompatibleDescriptionController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20.h),
                  AppButton(
                    isLoading: controller.isLoading2,
                    isSafeArea: false,
                    text: 'reviewed'.tr,
                    onPressed: () => controller.changeStatus(
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
