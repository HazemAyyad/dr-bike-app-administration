import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
    this.isLoading,
    this.isSafeArea = true,
  }) : super(key: key);

  final String text;
  final VoidCallback? onPressed;
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
  final bool isRtl;
  final RxBool? isLoading;
  final bool isSafeArea;

  @override
  Widget build(BuildContext context) {
    buttonBuilder() {
      final loading = isLoading?.value ?? false;

      return InkWell(
        onTap: loading ? null : onPressed,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        borderRadius: BorderRadius.circular(5.r),
        splashColor: loading ? Colors.transparent : Colors.white.withAlpha(76),
        highlightColor:
            loading ? Colors.transparent : Colors.white.withAlpha(51),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor ?? Colors.transparent,
              width: borderWidth ?? 0,
            ),
            color: loading ? Colors.grey : (color ?? getButtonTheme()),
            borderRadius: borderRadius ?? BorderRadius.circular(11.r),
          ),
          child: Container(
            height: height,
            width: width,
            alignment: Alignment.center,
            padding: padding ??
                EdgeInsets.symmetric(
                  vertical: 10.h,
                  horizontal: 10.w,
                ),
            margin: margin,
            child: loading
                ? SizedBox(
                    height: 22.h,
                    width: 22.h,
                    child: const CircularProgressIndicator(strokeWidth: 3),
                  )
                : _buildContent(context),
          ),
        ),
      );
    }

    final button = isLoading != null ? Obx(buttonBuilder) : buttonBuilder();

    return isSafeArea
        ? SafeArea(child: Column(children: [button, SizedBox(height: 20.h)]))
        : button;
  }

  Widget _buildContent(BuildContext context) {
    if (widget != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isRtl) widget!,
          Text(
            text.tr,
            style: textStyle ??
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: textColor ?? AppColors.whiteColor,
                      fontSize: size ?? 16.sp,
                      fontWeight: fontWeight ?? FontWeight.w700,
                    ),
          ),
          if (!isRtl) widget!,
        ],
      );
    } else {
      return Text(
        text.tr,
        style: textStyle ??
            Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: textColor ?? AppColors.whiteColor,
                  fontSize: size ?? 16.sp,
                  fontWeight: fontWeight ?? FontWeight.w700,
                ),
      );
    }
  }
}
