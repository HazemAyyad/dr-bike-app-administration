import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/login_controller.dart';

class RememberMe extends StatelessWidget {
  const RememberMe({Key? key, required this.controller}) : super(key: key);

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ValueListenableBuilder(
              valueListenable: controller.isRemember,
              builder: (context, value, _) {
                return Checkbox(
                  activeColor: AppColors.primaryColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  value: value as bool,
                  onChanged: (val) =>
                      controller.isRemember.value = val ?? false,
                );
              },
            ),
            Text(
              'rememberMe'.tr,
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
        TextButton(
          style: TextButton.styleFrom(
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            padding: EdgeInsets.zero,
          ),
          onPressed: () {},
          child: Text(
            'forgotPassword'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.graywhiteColor
                      : AppColors.customGreyColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
      ],
    );
  }
}
