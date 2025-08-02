import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../my_orders/widgets/row_text.dart';

Container followUpTableHeader(BuildContext context, controller) {
  return Container(
    height: 32.h,
    decoration: BoxDecoration(
      color: ThemeService.isDark.value
          ? AppColors.secondaryColor
          : AppColors.primaryColor,
      borderRadius: BorderRadius.circular(6.r),
    ),
    child: Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // SizedBox(),
          rowText(context, 'customerName'),
          // SizedBox(),
          rowText(context, 'productDetails'),
          rowText(context, 'startDate'),
          if (controller.currentTab.value == 0)
            Flexible(child: SizedBox(width: 170.w))
        ],
      ),
    ),
  );
}
