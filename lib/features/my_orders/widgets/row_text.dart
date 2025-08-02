import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_colors.dart';

Text rowText(
  BuildContext context,
  String text, {
  Color? color,
  double? size,
  FontWeight? fontWeight,
  int? maxLines,
  TextAlign? textAlign,
}) {
  return Text(
    text.tr,
    maxLines: maxLines,
    textAlign: textAlign,
    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: size ?? 12.sp,
          fontWeight: fontWeight ?? FontWeight.w400,
          color: color ?? AppColors.whiteColor,
        ),
  );
}
