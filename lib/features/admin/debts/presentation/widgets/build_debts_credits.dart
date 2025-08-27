import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';

class BuildDebtsAndCredits extends StatelessWidget {
  const BuildDebtsAndCredits({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final String amount;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165.w,
      height: 70.h,
      decoration: BoxDecoration(
        color:
            Get.isDarkMode ? AppColors.customGreyColor4 : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Get.isDarkMode
                ? AppColors.customGreyColor2
                : AppColors.customGreyColor3,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AssetsManger.cashIcon,
                width: 20.w,
                height: 20.h,
                color: color,
              ),
              SizedBox(width: 5.w),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            '${NumberFormat("#,###").format(double.parse(amount))} ${'currency'.tr}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
