import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';

class CustomDataWidget extends StatelessWidget {
  const CustomDataWidget({
    Key? key,
    required this.onTap,
    required this.title,
    required this.value,
    this.onLongPress,
  }) : super(key: key);

  final Function() onTap;
  final String title;
  final String value;
  final Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title.isNotEmpty)
              Text(
                title.tr,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor
                          : AppColors.secondaryColor,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            SizedBox(height: 5.h),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
