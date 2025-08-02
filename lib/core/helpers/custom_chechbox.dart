import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class CustomChechbox extends StatelessWidget {
  const CustomChechbox({
    Key? key,
    required this.titale,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String titale;
  final RxBool value;
  final void Function(bool?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Obx(
          () => Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
            side: BorderSide(color: AppColors.primaryColor),
            value: value.value,
            onChanged: onChanged,
          ),
        ),
        Flexible(
          child: Text(
            titale.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? Colors.white
                      : AppColors.secondaryColor,
                ),
          ),
        ),
      ],
    );
  }
}
