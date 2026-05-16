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

class Helpers {
  //showCustomDialogError
  static void showCustomDialogError({
    required BuildContext context,
    required String title,
    required String message,
  }) {
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
                horizontal: 16.w,
                vertical: 16.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AssetsManager.errorAnimationImage,
                      height: 90.h,
                      width: 90.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      title.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: const Color(0XFFC01A1A),
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: const Color(0XFF8C9191),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                      // maxLines: 2,
                      // overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFFC01A1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        minimumSize: Size(
                            double.infinity, 47.h), // عرض الزر 100% من الشاشة
                      ),
                      onPressed: () {
                        Get.back(); // إغلاق الـ Dialog
                      },
                      child: Text(
                        'tryAgain'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

//showCustomDialogSuccess
  static void showCustomDialogSuccess({
    required BuildContext context,
    required String title,
    required String message,
    Duration autoCloseAfter = const Duration(seconds: 2),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0XFFD9D9D9).withOpacity(0.55),
      builder: (dialogContext) {
        return _AutoCloseSuccessDialog(
          title: title,
          message: message,
          autoCloseAfter: autoCloseAfter,
        );
      },
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
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0XFFD9D9D9).withOpacity(0.55),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // الزوايا المستديرة
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // 80% من عرض الشاشة
            decoration: BoxDecoration(
              color: Colors.white,
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
                    AssetsManager.errorImage,
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
}

/// Success dialog that closes itself after [autoCloseAfter].
class _AutoCloseSuccessDialog extends StatefulWidget {
  const _AutoCloseSuccessDialog({
    required this.title,
    required this.message,
    required this.autoCloseAfter,
  });

  final String title;
  final String message;
  final Duration autoCloseAfter;

  @override
  State<_AutoCloseSuccessDialog> createState() =>
      _AutoCloseSuccessDialogState();
}

class _AutoCloseSuccessDialogState extends State<_AutoCloseSuccessDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.autoCloseAfter > Duration.zero) {
      Future.delayed(widget.autoCloseAfter, _closeIfMounted);
    }
  }

  void _closeIfMounted() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              Image.asset(
                AssetsManager.successAnimation,
                height: ScreenUtilNew.height(89),
                width: ScreenUtilNew.width(89),
                fit: BoxFit.contain,
              ),
              SizedBox(height: ScreenUtilNew.height(4)),
              Text(
                widget.title.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0XFF39C67E),
                ),
              ),
              SizedBox(height: ScreenUtilNew.height(4)),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0XFF8C9191),
                ),
              ),
              SizedBox(height: ScreenUtilNew.height(24)),
            ],
          ),
        ),
      ),
    );
  }
}
