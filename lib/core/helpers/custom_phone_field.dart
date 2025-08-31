import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../utils/app_colors.dart';
import '../validator/validator.dart';

class CustomPhoneField extends StatelessWidget {
  const CustomPhoneField({
    Key? key,
    required this.controller,
    this.hintText,
    this.label = '',
    this.isRequired = false,
    this.textInputAction,
  }) : super(key: key);

  final TextEditingController controller;
  final String? hintText;
  final String label;
  final bool isRequired;
  final TextInputAction? textInputAction;

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
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: (ThemeService.isDark.value
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
        SizedBox(height: 10.h),
        Directionality(
          textDirection: TextDirection.ltr,
          child: IntlPhoneField(
            textInputAction: textInputAction ?? TextInputAction.next,
            keyboardType: TextInputType.phone,
            dropdownDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
            ),
            textAlign: TextAlign.left,
            dropdownTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? Colors.white
                      : AppColors.primaryColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                ),
            dropdownIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryColor,
            ),
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                gapPadding: 1.w,
                borderSide: BorderSide(color: Colors.transparent),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                borderSide: BorderSide(color: Colors.transparent, width: 0),
              ),
              suffixIcon: hintText != null
                  ? null
                  : Icon(Icons.phone, color: AppColors.primaryColor),
              filled: true,
              fillColor: (ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2),
              labelText:
                  controller.text.isEmpty ? hintText!.tr : controller.text,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                gapPadding: 1,
                borderSide: BorderSide(color: AppColors.customGreyColor3),
              ),
              labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: (ThemeService.isDark.value
                        ? AppColors.customGreyColor2
                        : AppColors.customGreyColor6),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            ),
            initialCountryCode: 'SA',
            showCountryFlag: true,
            countries: const [
              Country(
                code: "PS",
                dialCode: '970',
                name: 'Palestin 2',
                flag: "",
                nameTranslations: {'ar': 'فلسطين 2', 'en': 'Palestin 2'},
                minLength: 9,
                maxLength: 9,
              ),
              // Country(
              //   code: 'SA',
              //   dialCode: '966',
              //   name: 'Saudi Arabia',
              //   flag: '',
              //   nameTranslations: {
              //     'ar': 'السعودية',
              //     'en': 'Saudi Arabia',
              //   },
              //   minLength: 9,
              //   maxLength: 9,
              // ),
              Country(
                code: 'IL',
                dialCode: '972',
                name: 'Palestine',
                flag: '',
                nameTranslations: {'ar': 'فلسطين', 'en': 'Palestine'},
                minLength: 9,
                maxLength: 10,
              ),
            ],
            onChanged: (phone) {
              controller.text = "${phone.countryCode} ${phone.number}";
            },
            validator: (value) => Validators.validatePhoneNumber(
              value.toString(),
              controller.text,
            ),
          ),
        ),
      ],
    );
  }
}
