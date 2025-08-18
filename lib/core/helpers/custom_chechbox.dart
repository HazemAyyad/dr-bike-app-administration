import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class CustomCheckBox extends StatelessWidget {
  const CustomCheckBox({
    Key? key,
    required this.title,
    this.subtitle,
    required this.value,
    this.style,
    this.shape,
    required this.onChanged,
    this.scale = 1.0,
  }) : super(key: key);

  final String title;
  final String? subtitle;
  final RxBool value;
  final TextStyle? style;
  final CircleBorder? shape;
  final void Function(bool?) onChanged;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Obx(
          () => Transform.scale(
            scale: scale,
            child: Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppColors.primaryColor,
              shape: shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
              side: BorderSide(color: AppColors.primaryColor),
              value: value.value,
              onChanged: onChanged,
            ),
          ),
        ),
        subtitle == null
            ? Flexible(
                child: Text(
                  title.tr,
                  style: style ??
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                            color: ThemeService.isDark.value
                                ? Colors.white
                                : AppColors.secondaryColor,
                          ),
                ),
              )
            : Flexible(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        subtitle!.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
