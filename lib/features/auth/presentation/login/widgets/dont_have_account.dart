import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class DontHaveAccount extends StatelessWidget {
  const DontHaveAccount({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${'dontHaveAccount'.tr} ',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: ThemeService.isDark.value
                    ? AppColors.graywhiteColor
                    : AppColors.customGreyColor4,
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
              ),
        ),
        GestureDetector(
          onTap: () {
            Get.offNamed(AppRoutes.SIGNUPSCREEN);
          },
          child: Text(
            'register'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
