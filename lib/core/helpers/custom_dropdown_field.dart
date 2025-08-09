// بناء حقل قائمة منسدلة
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isRequired;
  final TextStyle? labelTextStyle;
  final BoxBorder? border;
  final bool isEnabled;
  final String? Function(String?)? validator;
  const CustomDropdownField({
    Key? key,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.labelTextStyle,
    this.border,
    this.isEnabled = true,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label == ''
            ? const SizedBox.shrink()
            : Row(
                children: [
                  Text(
                    label.tr,
                    style: labelTextStyle ??
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.customGreyColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                            ),
                  ),
                  isRequired
                      ? Text(
                          '*',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.red,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        )
                      : Container(),
                ],
              ),
        label == '' ? const SizedBox.shrink() : SizedBox(height: 5.h),
        Container(
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            border: border ?? Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: DropdownButtonFormField<String>(
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return label.tr;
                  }
                  return null;
                },
            enableFeedback: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 15.w),
            ),
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 24.sp,
              color: AppColors.primaryColor,
            ),
            hint: Text(
              hint.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor2
                        : AppColors.customGreyColor6,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
              // textAlign: TextAlign.right,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                )
                .toList(),
            onChanged: isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
