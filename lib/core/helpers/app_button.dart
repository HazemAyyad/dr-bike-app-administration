// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

import '../utils/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.size,
    this.fontWeight,
    this.margin,
    this.padding,
    this.textStyle,
    this.height,
    this.width,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.widget,
    this.isRtl = false,
  }) : super(key: key);

  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final double? size;
  final FontWeight? fontWeight;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final Widget? widget;
  final bool? isRtl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      borderRadius: BorderRadius.circular(5.r),
      splashColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.2),
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: borderWidth ?? 0,
          ),
          color: color ?? getButtonTheme(),
          borderRadius: borderRadius ?? BorderRadius.circular(11.r),
        ),
        child: Container(
          height: height,
          width: width,
          alignment: Alignment.center,
          padding:
              padding ?? EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
          margin: margin,
          child: widget != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isRtl! ? widget! : SizedBox(),
                    Text(
                      text.tr,
                      style: textStyle ??
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: textColor ?? getTextTheme(),
                                fontSize: size ?? 16.sp,
                                fontWeight: FontWeight.w400,
                              ),
                    ),
                    isRtl! ? SizedBox() : widget!,
                  ],
                )
              : Text(
                  text.tr,
                  style: textStyle ??
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: textColor ?? getTextTheme(),
                            fontSize: size ?? 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                ),
        ),
      ),
    );
  }
}
