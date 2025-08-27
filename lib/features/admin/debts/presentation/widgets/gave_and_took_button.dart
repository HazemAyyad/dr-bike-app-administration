import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import 'creat_debts.dart';

class GaveAndTookButton extends StatelessWidget {
  const GaveAndTookButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.bottomSheet(
                  CreateDebts(
                    title: 'create_debt_for_us',
                    supTitle: 'gave',
                    color: Colors.red,
                  ),
                  ignoreSafeArea: false,
                  isScrollControlled: true,
                  backgroundColor: ThemeService.isDark.value
                      ? AppColors.darckColor
                      : Colors.white,
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 30.h, left: 15.w, right: 15.w),
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    'gave'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.bottomSheet(
                  CreateDebts(
                    title: 'create_debt_on_us',
                    supTitle: 'took',
                    color: Colors.green,
                  ),
                  ignoreSafeArea: false,
                  isScrollControlled: true,
                  backgroundColor: ThemeService.isDark.value
                      ? AppColors.darckColor
                      : Colors.white,
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 30.h, left: 15.w, right: 15.w),
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    'took'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
