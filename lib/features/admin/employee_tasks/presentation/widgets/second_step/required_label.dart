import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';

class BuildRequiredLabel extends StatelessWidget {
  const BuildRequiredLabel({
    required this.label,
    Key? key,
  }) : super(key: key);

  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
          ),
          Text(
            '*',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.red,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
          )
        ],
      ),
    );
  }
}
