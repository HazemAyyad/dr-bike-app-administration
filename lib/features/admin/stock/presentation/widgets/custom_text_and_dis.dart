import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class CustomTextAndDis extends StatelessWidget {
  const CustomTextAndDis({
    Key? key,
    required this.title,
    required this.discription,
    this.noSized = false,
    this.titleColor,
    this.discriptionColor,
  }) : super(key: key);
  final String title;
  final String discription;
  final bool noSized;
  final Color? titleColor;
  final Color? discriptionColor;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        discriptionColor != null
            ? Container(
                padding: EdgeInsets.all(5.h),
                decoration: BoxDecoration(
                  color: discriptionColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "${title.tr}: ",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                      TextSpan(
                        text: discription,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                      )
                    ],
                  ),
                ),
              )
            : Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${title.tr}: ",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: titleColor ??
                                (ThemeService.isDark.value
                                    ? AppColors.customGreyColor6
                                    : AppColors.customGreyColor),
                          ),
                    ),
                    TextSpan(
                      text: discription,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w400,
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor6
                                : AppColors.customGreyColor,
                          ),
                    )
                  ],
                ),
              ),
        noSized
            ? const SizedBox.shrink()
            : Center(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  height: 1.h,
                  width: 300.w,
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor3,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
      ],
    );
  }
}
