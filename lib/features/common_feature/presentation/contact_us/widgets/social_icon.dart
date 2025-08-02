import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildSocialIcon(
  BuildContext context, {
  required String iconAsset,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Image.asset(
      iconAsset,
      height: 50.h,
      width: 50.w,
    ),
  );
}
