// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../utils/assets_manger.dart';
import '../utils/screen_util_new.dart';
import 'app_failure_notice.dart';
import 'app_success_notice.dart';

class Helpers {
  //showCustomDialogError
  static void showCustomDialogError({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    AppFailureNotice.showBlocking(
      context: context,
      title: title,
      message: message,
      barrierDismissible: false,
      actionLabel: 'tryAgain'.tr,
    );
  }

//showCustomDialogSuccess
  static void showCustomDialogSuccess({
    required BuildContext context,
    required String title,
    required String message,
    Duration autoCloseAfter = AppSuccessNotice.defaultDuration,
  }) {
    AppSuccessNotice.show(
      context: context,
      title: title,
      message: message,
      duration: AppSuccessNotice.defaultDuration,
    );
  }

  //showCustomDialogSecondaryError
  static void showCustomDialogSecondarySucess(
      {required BuildContext context,
      required String title,
      required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0XFFD9D9D9).withOpacity(0.55),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // الزوايا المستديرة
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // 80% من عرض الشاشة
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.darkColor
                  : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenUtilNew.width(16),
                vertical: ScreenUtilNew.height(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AssetsManager.sucessImageSvg,
                    height: ScreenUtilNew.height(89),
                    width: ScreenUtilNew.width(89),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: ScreenUtilNew.height(4)),
                  Text(
                    title.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: ScreenUtilNew.height(4)),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0XFF8C9191),
                    ),
                    // maxLines: 2,
                    // overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //showCustomDialogSecondaryError
  static void showCustomDialogSecondaryError(
      {required BuildContext context,
      required String title,
      required String message}) {
    AppFailureNotice.showBlocking(
      context: context,
      title: title,
      message: message,
      barrierDismissible: true,
    );
  }
}
