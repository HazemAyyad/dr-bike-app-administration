import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../../core/services/theme_service.dart';
import '../../../../../../../core/utils/app_colors.dart';

Widget supTextAndDis(BuildContext context, title, discription) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 15.h),
      Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: "${'$title'.tr}: ",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor4,
                  ),
            ),
            TextSpan(
              text: discription,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor4,
                  ),
            )
          ],
        ),
      ),
    ],
  );
}
