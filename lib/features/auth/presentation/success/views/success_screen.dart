import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';

class SignUpSuccessScreen extends StatelessWidget {
  const SignUpSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AssetsManger.sucessImage,
                height: 160.h,
                width: 160.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 50.h),
              Text(
                'verificationSuccess'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.customGreyColor,
                      fontSize: 29.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: 100.h),
              AppButton(
                text: 'next',
                onPressed: () {
                  Get.offAllNamed(AppRoutes.LOGINSCREEN);
                },
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.secondaryColor
                          : AppColors.whiteColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                height: 48.h,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
