import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class ViewChecksWidget extends StatelessWidget {
  final Map<String, dynamic> check;
  final bool? shadowed;
  final int? currentTab;
  const ViewChecksWidget({
    Key? key,
    required this.check,
    this.shadowed = true,
    this.currentTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: shadowed == true
            ? [
                BoxShadow(
                  color: Colors.grey.withAlpha(32),
                  blurRadius: 5.r,
                  spreadRadius: 2.r,
                  offset: Offset(0, 0),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      width: 65.w,
                      height: 65.h,
                      decoration: BoxDecoration(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.customGreyColor6,
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(30),
                            blurRadius: 5.r,
                            spreadRadius: 2.r,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "${NumberFormat('#,###').format(int.parse(check['total'].toString()))} ${'currency'.tr}",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${'checkNumber'.tr} : ${check['checkNumber'] ?? ''}",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.withAlpha(500),
                            ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        "${'due_date'.tr} : ${check['date']}",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.withAlpha(500),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 60.w,
            height: 75.h,
            decoration: BoxDecoration(
              color: int.parse(check['days']) > 5
                  ? AppColors.customGreen1
                  : int.parse(check['days']) > 0
                      ? AppColors.customOrange3
                      : AppColors.redColor,
              borderRadius: Get.locale!.languageCode == 'en'
                  ? BorderRadius.only(
                      topRight: Radius.circular(4.r),
                      bottomRight: Radius.circular(4.r),
                    )
                  : BorderRadius.only(
                      topLeft: Radius.circular(4.r),
                      bottomLeft: Radius.circular(4.r),
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  currentTab == 2 ? check['status'] : check['days'] ?? '0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
                SizedBox(height: 5.h),
                currentTab == 2
                    ? SizedBox()
                    : Text(
                        int.parse(check['days']) > 10 ||
                                int.parse(check['days']) < -10
                            ? 'days'.tr
                            : 'dayss'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
