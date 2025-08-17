import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';

class OnboardingItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingItem({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Expanded(
            child: Image.asset(imagePath),
          ),
          SizedBox(height: 20.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.secondaryColor,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: 20.h),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.graywhiteColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}
