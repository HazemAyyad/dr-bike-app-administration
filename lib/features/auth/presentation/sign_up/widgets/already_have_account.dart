import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class AlreadyHaveAccount extends StatelessWidget {
  const AlreadyHaveAccount({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${"alreadyHaveAccount".tr} ",
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
            Get.offNamed(AppRoutes.LOGINSCREEN);
          },
          child: Text(
            "submit".tr,
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
