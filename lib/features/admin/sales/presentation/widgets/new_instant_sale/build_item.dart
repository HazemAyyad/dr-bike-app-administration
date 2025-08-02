import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';

Widget buildItem(BuildContext context, ItemModel item, int index,
    Animation<double> animation) {
  return SizeTransition(
    sizeFactor: animation,
    child: Row(
      children: [
        Expanded(
          child: CustomTextField(
            isRequired: true,
            label: 'quantity',
            labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
            hintText: 'discountExample',
            hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.customGreyColor6,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
            controller: item.quantityController,
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: CustomTextField(
            isRequired: true,
            label: 'price',
            labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
            hintText: 'totalExample',
            hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.customGreyColor6,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
            controller: item.priceController,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    ),
  );
}
