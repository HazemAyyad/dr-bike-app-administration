import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.suffixIcon,
    this.enabled = true,
    this.fillColor,
    this.labelColor,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.hintColor,
    this.obscureText = false,
    this.isRequired = false,
    this.suffix,
    this.labelTextstyle,
    this.suffixIconColor,
    this.border,
    this.decoration,
    this.hintStyle,
    this.minLines,
    this.maxLines,
    this.sizedBox,
    this.onChanged,
  }) : super(key: key);

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final bool enabled;
  final Color? fillColor;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Color? labelColor;
  final String? Function(String?)? validator;
  final Color? hintColor;
  final bool obscureText;
  final bool isRequired;
  final Widget? suffix;
  final TextStyle? labelTextstyle;
  final Color? suffixIconColor;
  final InputBorder? border;
  final Decoration? decoration;
  final TextStyle? hintStyle;
  final int? minLines;
  final int? maxLines;
  final bool? sizedBox;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label == ''
            ? const SizedBox.shrink()
            : Text.rich(
                TextSpan(
                  text: label.tr,
                  style: labelTextstyle ??
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: labelColor ??
                                (ThemeService.isDark.value
                                    ? AppColors.customGreyColor6
                                    : AppColors.customGreyColor),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                  children: isRequired
                      ? [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]
                      : [],
                ),
              ),
        sizedBox == false || label == ''
            ? const SizedBox.shrink()
            : SizedBox(height: 10.h),
        Container(
          decoration: decoration,
          child: TextFormField(
            onChanged: onChanged,
            minLines: minLines ?? 1,
            maxLines: maxLines ?? 1,
            obscureText: obscureText,
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor ??
                  (ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2),
              hintText: hintText.tr,
              hintStyle: hintStyle ??
                  Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: hintColor ??
                            (ThemeService.isDark.value
                                ? AppColors.customGreyColor2
                                : AppColors.customGreyColor6),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                      ),
              suffix: suffix,
              suffixIcon: suffixIcon,
              suffixIconColor: suffixIconColor,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 13.h, horizontal: 10.w),
              border: border ??
                  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    gapPadding: 1.w,
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
              enabledBorder: border ??
                  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    gapPadding: 1.w,
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                borderSide: const BorderSide(color: Colors.transparent, width: 0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                gapPadding: 1.w,
                borderSide: const BorderSide(
                  color: AppColors.secondaryColor,
                  width: 2,
                ),
              ),
            ),
            keyboardType: keyboardType,
            textInputAction: textInputAction ?? TextInputAction.next,
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return label.tr;
                  }
                  return null;
                },
          ),
        ),
      ],
    );
  }
}
