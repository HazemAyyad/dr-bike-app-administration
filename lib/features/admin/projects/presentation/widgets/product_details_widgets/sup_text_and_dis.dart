import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';

class SupTextAndDis extends StatelessWidget {
  const SupTextAndDis({
    Key? key,
    required this.title,
    required this.discription,
    this.showLine = true,
  }) : super(key: key);

  final String title;
  final String discription;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: "${title.tr}: ",
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
        SizedBox(height: 5.h),
        if (showLine)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  margin:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 50.w),
                  height: 1.h,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor3,
                ),
              ),
            ],
          )
      ],
    );
  }
}
