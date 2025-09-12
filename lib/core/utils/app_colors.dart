import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class AppColors {
  //Colors in App

  /// #6B65BD
  static const Color primaryColor = Color(0XFF6B65BD);

  /// #0F0F31
  static const Color secondaryColor = Color(0XFF0F0F31);

  /// #09113394
  static const Color dubleColor = Color.fromRGBO(17, 51, 148, 0.035);

  static const Color darckColor = Color(0XFF121212);

  /// #FFFFFF
  static const Color whiteColor = Color(0XFFFFFFFF);

  /// #EEEEEE
  static const Color whiteColor2 = Color(0XFFEEEEEE);

// dark mode
  /// #AFAFAE
  static const Color graywhiteColor = Color(0XFFAFAFAE);

  /// #333333
  static const Color customGreyColor = Color(0XFF333333);

  static const Color customGreyColor2 = Color(0XFF878787);

  static const Color customGreyColor3 = Color(0XFFB1B1B1);

// dark mode
  /// #4B4B4B
  static const Color customGreyColor4 = Color(0XFF4B4B4B);

  /// #7F7F7F
  static const Color customGreyColor5 = Color(0XFF7F7F7F);

  /// #C6C6C6
  static const Color customGreyColor6 = Color(0XFFC6C6C6);

  static const Color customGreen = Color(0XFF0A4F01);

  static const Color customGreen1 = Color(0XFF34C759);

  static const Color customGreen2 = Color(0XFF5AED47);

  static const Color customOrange = Color(0XFFEDED47);

  static const Color customOrange2 = Color(0XFF8A6F02);

  /// #FFCC00
  static const Color customOrange3 = Color(0XFFFFCC00);

  static const Color customRed = Color(0XFF530400);
// ==============================================================================
  static const Color blackColor = Color(0XFF000000);
  static const Color greyColor = Color(0XFF666666);
  static const Color lightGreyColor = Color(0XFFD4D4D4);
  static const Color veryLightGreyColor = Color(0XFF949494);
  static const Color currncyColor = Color(0xff818181);
  static const Color redColor = Color(0XFFC01A1A);
}

Color getButtonTheme() {
  return ThemeService.isDark.value
      ? AppColors.primaryColor
      : AppColors.secondaryColor;
}

// Color getTextTheme() {
//   // final bool isDarkMode = Theme.of(Get.context!).brightness == Brightness.dark;
//   final buttonColor = const Color(0xFFFFFFFF);
//   return buttonColor;
// }
