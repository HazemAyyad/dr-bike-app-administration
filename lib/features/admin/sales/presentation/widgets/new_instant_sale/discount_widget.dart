import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';

class DiscountWidget extends GetView<SalesController> {
  const DiscountWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'discount',
                hintText: 'discountExample',
                controller: controller.discountController,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: CustomTextField(
                isRequired: true,
                label: 'totalBill',
                hintText: 'totalExample',
                controller: controller.totalController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        CustomTextField(
          minLines: 3,
          maxLines: 5,
          label: 'details',
          hintText: 'detailsExample',
          controller: controller.noteController,
          validator: (value) {
            return null;
          },
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Text(
              'readItem'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
            )
          ],
        ),
        SizedBox(height: 7.h),
        Row(
          children: [
            Text(
              'readQuantity'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
            )
          ],
        ),
      ],
    );
  }
}
