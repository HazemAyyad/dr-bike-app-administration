import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/app_colors.dart';

class OnBoardingButton extends StatelessWidget {
  final int progress;
  final VoidCallback onTap;

  const OnBoardingButton({
    Key? key,
    required this.progress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: progress == 0
                  ? 0.25
                  : progress == 1
                      ? 0.50
                      : progress == 2
                          ? 0.75
                          : 1,
            ),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return GestureDetector(
                onTap: onTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70.w,
                      height: 70.h,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3.5,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      width: 60.w,
                      height: 60.h,
                      duration: const Duration(milliseconds: 300),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.secondaryColor,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
