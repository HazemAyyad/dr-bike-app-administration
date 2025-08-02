import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart' show ThemeService;
import '../../../../../core/utils/app_colors.dart';
import '../../../../my_orders/widgets/row_text.dart';

Container globalDataList(BuildContext context) {
  return Container(
    height: 32.h,
    decoration: BoxDecoration(
      color: ThemeService.isDark.value
          ? AppColors.secondaryColor
          : AppColors.primaryColor,
      borderRadius: BorderRadius.circular(6.r),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        rowText(context, 'customerName'),
        // SizedBox(),
        rowText(context, 'customerPhoneNumber'),
        rowText(context, 'job'),
      ],
    ),
  );
}
