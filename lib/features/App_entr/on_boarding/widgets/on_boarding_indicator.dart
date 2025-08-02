import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../controllers/on_boarding_controller.dart';

class OnBoardingIndicator extends StatelessWidget {
  const OnBoardingIndicator({Key? key, required this.controller})
      : super(key: key);

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) {
              final isActive = controller.currentPage.value == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: isActive ? 34.w : 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryColor : Colors.grey,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
