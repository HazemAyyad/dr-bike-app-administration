import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: "${"termsNotice".tr.split('  ')[0]} ",
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: ThemeService.isDark.value
                  ? AppColors.graywhiteColor
                  : AppColors.customGreyColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
            ),
        children: [
          TextSpan(
            text: "termsNotice".tr.split('  ')[1],
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // افتح صفحة الشروط أو اعمل اللي تحبه هنا
              },
          ),
          TextSpan(
            text: " ${"termsNotice".tr.split('  ')[2]}",
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.graywhiteColor
                      : AppColors.customGreyColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}
