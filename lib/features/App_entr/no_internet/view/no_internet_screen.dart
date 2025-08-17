import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/helpers/app_button.dart';
import '../../../../core/services/initial_bindings.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../routes/app_routes.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "noInternet".tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.primaryColor,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 50.h),
              AppButton(
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.primaryColor,
                textColor: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : Colors.white,
                onPressed: () {
                  InitialBindings().dependencies();
                  Get.offAllNamed(AppRoutes.SPLASHSCREEN);
                },
                text: 'tryAgain',
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
