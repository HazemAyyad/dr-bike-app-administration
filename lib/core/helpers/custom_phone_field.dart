import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/services/theme_service.dart';

import '../utils/app_colors.dart';

// class CustomPhoneField extends StatelessWidget {
//   const CustomPhoneField({
//     Key? key,
//     required this.controller,
//     this.hintText,
//     this.label = '',
//     this.isRequired = false,
//     this.textInputAction,
//   }) : super(key: key);

//   final TextEditingController controller;
//   final String? hintText;
//   final String label;
//   final bool isRequired;
//   final TextInputAction? textInputAction;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         label == ''
//             ? const SizedBox.shrink()
//             : Text.rich(
//                 TextSpan(
//                   text: label.tr,
//                   style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                         color: (ThemeService.isDark.value
//                             ? AppColors.customGreyColor6
//                             : AppColors.customGreyColor),
//                         fontSize: 15.sp,
//                         fontWeight: FontWeight.w400,
//                       ),
//                   children: isRequired
//                       ? [
//                           TextSpan(
//                             text: '*',
//                             style: TextStyle(
//                               color: Colors.red,
//                               fontSize: 15.sp,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ]
//                       : [],
//                 ),
//               ),
//         SizedBox(height: 10.h),
//         Directionality(
//           textDirection: TextDirection.ltr,
//           child: IntlPhoneField(
//             textInputAction: textInputAction ?? TextInputAction.next,
//             keyboardType: TextInputType.phone,
//             dropdownDecoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8.r),
//             ),
//             textAlign: TextAlign.left,
//             dropdownTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                   color: ThemeService.isDark.value
//                       ? Colors.white
//                       : AppColors.primaryColor,
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.w400,
//                 ),
//             dropdownIcon: const Icon(
//               Icons.arrow_drop_down,
//               color: AppColors.primaryColor,
//             ),
//             decoration: InputDecoration(
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(11.r),
//                 gapPadding: 1.w,
//                 borderSide: const BorderSide(color: Colors.transparent),
//               ),
//               disabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(11.r),
//                 borderSide: const BorderSide(color: Colors.transparent, width: 0),
//               ),
//               suffixIcon: hintText != null
//                   ? null
//                   : const Icon(Icons.phone, color: AppColors.primaryColor),
//               filled: true,
//               fillColor: (ThemeService.isDark.value
//                   ? AppColors.customGreyColor
//                   : AppColors.whiteColor2),
//               labelText:
//                   controller.text.isEmpty ? hintText!.tr : controller.text,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8.r),
//                 gapPadding: 1,
//                 borderSide: const BorderSide(color: AppColors.customGreyColor3),
//               ),
//               labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                     color: (ThemeService.isDark.value
//                         ? AppColors.customGreyColor2
//                         : AppColors.customGreyColor6),
//                     fontSize: 15.sp,
//                     fontWeight: FontWeight.w400,
//                   ),
//               contentPadding:
//                   EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
//             ),
//             initialCountryCode: 'SA',
//             showCountryFlag: true,
//             countries: const [
//               Country(
//                 code: "PS",
//                 dialCode: '970',
//                 name: 'Palestin 2',
//                 flag: "",
//                 nameTranslations: {'ar': 'فلسطين 2', 'en': 'Palestin 2'},
//                 minLength: 9,
//                 maxLength: 9,
//               ),
//               // Country(
//               //   code: 'SA',
//               //   dialCode: '966',
//               //   name: 'Saudi Arabia',
//               //   flag: '',
//               //   nameTranslations: {
//               //     'ar': 'السعودية',
//               //     'en': 'Saudi Arabia',
//               //   },
//               //   minLength: 9,
//               //   maxLength: 9,
//               // ),
//               Country(
//                 code: 'IL',
//                 dialCode: '972',
//                 name: 'Palestine',
//                 flag: '',
//                 nameTranslations: {'ar': 'فلسطين', 'en': 'Palestine'},
//                 minLength: 9,
//                 maxLength: 10,
//               ),
//             ],
//             onChanged: (phone) {
//               controller.text = "${phone.countryCode} ${phone.number}";
//             },
//             validator: (value) => Validators.validatePhoneNumber(
//               value.toString(),
//               controller.text,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

class CountryData {
  final String code;
  final String dialCode;
  final String name;

  const CountryData({
    required this.code,
    required this.dialCode,
    required this.name,
  });
}

class CustomPhoneField extends StatefulWidget {
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
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField>
    with WidgetsBindingObserver {
  late FocusNode _focusNode;
  bool _wasFocused = false;
  bool _shouldKeepKeyboard = false;

  final List<CountryData> countries = const [
    CountryData(code: "PS", dialCode: "+970", name: "فلسطين"),
    CountryData(code: "IL", dialCode: "+972", name: "فلسطين"),
  ];

  late CountryData selectedCountry;
  late TextEditingController _phoneOnlyController;

  @override
  void didUpdateWidget(CustomPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // إذا تغير الـ controller من الخارج، حديث الـ phone only controller
    if (oldWidget.controller != widget.controller) {
      final phoneNumber = widget.controller.text
          .replaceFirst(selectedCountry.dialCode, "")
          .trim();
      _phoneOnlyController.text = phoneNumber;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    selectedCountry = widget.controller.text.contains('+970')
        ? countries.first
        : countries.last;

    // خزن الرقم فقط من controller الأساسي
    final initialNumber = widget.controller.text
        .replaceFirst(selectedCountry.dialCode, "")
        .trim();
    _phoneOnlyController = TextEditingController(text: initialNumber);

    // استمع لتغيير حالة Focus
    _focusNode.addListener(() {
      _shouldKeepKeyboard = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _phoneOnlyController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _wasFocused = _focusNode.hasFocus;
    } else if (state == AppLifecycleState.resumed) {
      // عند الرجوع للتطبيق، ارجع الفوكس فوراً
      if (_wasFocused || _shouldKeepKeyboard) {
        // تأكد إن الـ TextField مازال موجود
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focusNode.canRequestFocus) {
            _focusNode.requestFocus();
            // فرض إظهار الكيبورد
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        });
      }
    }
  }

  void _selectCountry() async {
    // احفظ حالة الكيبورد قبل فتح البوتوم شيت
    final wasKeyboardOpen = _focusNode.hasFocus;

    final country = await showModalBottomSheet<CountryData>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: countries
            .map(
              (c) => ListTile(
                title: Text("${c.name} (${c.dialCode})"),
                onTap: () => Navigator.pop(ctx, c),
              ),
            )
            .toList(),
      ),
    );

    if (country != null) {
      setState(() => selectedCountry = country);

      // بعد تغيير الدولة، خزن الرقم مع الكود الجديد
      widget.controller.text =
          "${selectedCountry.dialCode} ${_phoneOnlyController.text}";
    }

    // ارجع الكيبورد إذا كان مفتوح قبل البوتوم شيت
    if (wasKeyboardOpen) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label == ''
            ? const SizedBox.shrink()
            : Text.rich(
                TextSpan(
                  text: widget.label.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: (ThemeService.isDark.value
                            ? AppColors.customGreyColor6
                            : AppColors.customGreyColor),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                      ),
                  children: widget.isRequired
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _selectCountry,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  selectedCountry.dialCode,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                // maxLength: 10,
                focusNode: _focusNode,
                controller: _phoneOnlyController,
                onChanged: (value) {
                  // دايمًا نخزن الكود + الرقم في الكنترولر الأساسي
                  widget.controller.text = "${selectedCountry.dialCode} $value";
                },
                onTap: () {
                  // تأكد إن الكيبورد يفضل مفتوح
                  _shouldKeepKeyboard = true;
                },
                textInputAction: widget.textInputAction ?? TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: widget.hintText?.tr,
                  hintStyle: TextStyle(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor6,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIcon: const Icon(
                    Icons.phone,
                    color: AppColors.primaryColor,
                  ),
                  filled: true,
                  fillColor: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
