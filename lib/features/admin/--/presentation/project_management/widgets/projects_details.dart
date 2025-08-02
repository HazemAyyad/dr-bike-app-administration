import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../my_orders/widgets/row_text.dart';

Container projectsDetails(BuildContext context, order,
    {required String icon, required String tital}) {
  return Container(
    height: 62.h,
    width: 167.w,
    decoration: BoxDecoration(
      color:
          ThemeService.isDark.value ? AppColors.customGreyColor4 : Colors.white,
      borderRadius: BorderRadius.circular(5.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              height: 20.h,
            ),
            SizedBox(width: 5.w),
            Flexible(
              child: rowText(
                context,
                tital,
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.secondaryColor,
                fontWeight: FontWeight.w700,
                size: 15.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        rowText(
          context,
          icon == AssetsManger.frameIcon
              ? order[tital].toString()
              : '${order[tital]}%',
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          size: 14.sp,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ],
    ),
  );
}
