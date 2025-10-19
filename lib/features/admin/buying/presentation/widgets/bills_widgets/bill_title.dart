import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../employee/my_orders/widgets/row_text.dart';

class BillTitle extends StatelessWidget {
  const BillTitle({Key? key, required this.page}) : super(key: key);

  final String page;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      height: 32.h,
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.secondaryColor
            : AppColors.primaryColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox.shrink(),
          Flexible(child: RowText(title: 'productName')),
          Flexible(child: RowText(title: 'quantity')),
          Flexible(child: RowText(title: 'price')),
          Flexible(child: RowText(title: 'total')),
          Flexible(child: RowText(title: 'status')),
          Flexible(child: RowText(title: 'count')),
          SizedBox.shrink(),
        ],
      ),
    );
  }
}
