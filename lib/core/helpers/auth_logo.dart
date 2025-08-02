import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/theme_service.dart';
import '../utils/assets_manger.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ThemeService.isDark.value
          ? AssetsManger.logoNoNameDark
          : AssetsManger.logoNoNameWhite,
      height: 137.h,
      width: 191.w,
    );
  }
}
