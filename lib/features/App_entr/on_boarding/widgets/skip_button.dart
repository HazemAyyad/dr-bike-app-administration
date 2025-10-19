import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../controllers/on_boarding_controller.dart';

class SkipButton extends StatelessWidget {
  const SkipButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.currentPage.value == 3
          ? SizedBox(height: 60.h)
          : Align(
              alignment: Alignment.topLeft,
              child: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
                height: 40.h,
                width: 71.w,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor2,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextButton(
                  onPressed: controller.skip,
                  child: Text(
                    'skip'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ),
            ),
    );
  }
}
