import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../utils/app_colors.dart';
import '../validator/validator.dart';

class CustomPhoneField extends StatelessWidget {
  const CustomPhoneField({Key? key, required this.controller, this.hintText})
      : super(key: key);

  final TextEditingController controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8.h),
        Directionality(
          textDirection: TextDirection.ltr,
          child: IntlPhoneField(
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
              suffixIcon: hintText != null
                  ? null
                  : Icon(Icons.phone, color: AppColors.primaryColor),
              filled: true,
              fillColor: AppColors.primaryColor.withAlpha(4),
              labelText: controller.text.isEmpty ? hintText : controller.text,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                gapPadding: 1,
                borderSide: BorderSide(
                  color: AppColors.customGreyColor3,
                ),
              ),
              labelStyle: hintText != null
                  ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                      )
                  : Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                      ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            ),
            initialCountryCode: 'SA',
            showCountryFlag: true,
            countries: const [
              Country(
                code: 'PS',
                dialCode: '970',
                name: 'Palestine',
                flag: '',
                nameTranslations: {
                  'ar': 'فلسطين',
                  'en': 'Palestine',
                },
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
                name: 'Israel',
                flag: '',
                nameTranslations: {
                  'ar': 'إسرائيل',
                  'en': 'Israel',
                },
                minLength: 9,
                maxLength: 10,
              ),
            ],
            onChanged: (phone) {
              controller.text = phone.completeNumber;
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
