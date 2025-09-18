import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String>? items;
  final String? value;
  final Function(String?) onChanged;
  final bool isRequired;
  final TextStyle? labelTextStyle;
  final BoxBorder? border;
  final bool isEnabled;
  final String? Function(String?)? validator;
  final List<DropdownMenuItem<String>>? dropdownField;
  const CustomDropdownField({
    Key? key,
    required this.label,
    required this.hint,
    this.items,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.labelTextStyle,
    this.border,
    this.isEnabled = true,
    this.validator,
    this.dropdownField,
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
        label == '' ? const SizedBox.shrink() : SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            // border: border ?? Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
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
            items: dropdownField ??
                items!
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
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

class CustomDropdownFieldWithSearch extends StatelessWidget {
  final String tital;
  final String hint;
  final List<dynamic> items;
  final Function(dynamic) onChanged;
  final bool isRequired;
  final TextStyle? titalTextStyle;
  final bool isEnabled;
  final String Function(dynamic) itemAsString;
  final bool Function(dynamic, dynamic) compareFn;
  final FormFieldValidator<dynamic>? validator;
  final TextStyle? labelStyle;
  final dynamic value;

  const CustomDropdownFieldWithSearch({
    Key? key,
    required this.tital,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.titalTextStyle,
    this.isEnabled = true,
    required this.itemAsString,
    required this.compareFn,
    this.validator,
    this.labelStyle,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tital == ''
            ? const SizedBox.shrink()
            : Row(
                children: [
                  Text(
                    tital.tr,
                    style: titalTextStyle ??
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
        tital == '' ? const SizedBox.shrink() : SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: DropdownSearch<dynamic>(
            selectedItem: value,
            items: (filter, infiniteScrollProps) => items,
            itemAsString: itemAsString,
            compareFn: compareFn,
            validator: validator ??
                (value) {
                  if (value == null) {
                    return tital.tr;
                  }
                  return null;
                },
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15.w),
                labelText: hint.tr,
                labelStyle: labelStyle ??
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor2
                              : AppColors.customGreyColor6,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                        ),
              ),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
            onChanged: isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
