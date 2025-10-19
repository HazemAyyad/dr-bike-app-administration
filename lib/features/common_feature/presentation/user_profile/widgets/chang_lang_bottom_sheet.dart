import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/profile_controller.dart';

Future<dynamic> changLangBottomSheet(ProfileController controller) {
  return showModalBottomSheet(
    backgroundColor: Colors.transparent,
    context: Get.context!,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25.r),
          ),
        ),
        height: 210.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(25.r),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    'doctorBikeWillStartToApplyThisChange'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w400,
                          color: ThemeService.isDark.value
                              ? AppColors.primaryColor
                              : AppColors.dubleColor.withAlpha(128),
                        ),
                  ),
                  SizedBox(height: 10.h),
                  Divider(
                    color: AppColors.graywhiteColor.withAlpha(128),
                    thickness: 1.h,
                  ),
                  Get.locale!.languageCode == 'ar'
                      ? TextButton(
                          style: ButtonStyle(
                            shadowColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                          onPressed: () {
                            // Change to arabic logic
                            controller.languageController.changeLanguage('en');
                          },
                          child: SizedBox(
                            width: double.infinity,
                            height: 30.h,
                            child: Text(
                              'changeToEnglish'.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? AppColors.primaryColor
                                        : AppColors.secondaryColor,
                                  ),
                            ),
                          ),
                        )
                      : TextButton(
                          style: ButtonStyle(
                            shadowColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                          onPressed: () {
                            // Change to English logic
                            controller.languageController.changeLanguage('ar');
                          },
                          child: SizedBox(
                            width: double.infinity,
                            height: 30.h,
                            child: Text(
                              'changeToArabic'.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeService.isDark.value
                                        ? AppColors.primaryColor
                                        : AppColors.secondaryColor,
                                  ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            // Divider(),
            SizedBox(height: 10.h),
            Container(
              height: 55.h,
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(25.r),
                ),
              ),
              child: TextButton(
                style: ButtonStyle(
                  shadowColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                  overlayColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                ),
                onPressed: () {
                  Get.back();
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 30.h,
                  child: Text(
                    'cancel'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: ThemeService.isDark.value
                              ? AppColors.primaryColor
                              : AppColors.secondaryColor,
                        ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15.h),
          ],
        ),
      );
    },
  );
}
