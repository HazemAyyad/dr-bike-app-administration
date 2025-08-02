import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class MovementsWidget extends StatelessWidget {
  const MovementsWidget({Key? key, required this.box}) : super(key: key);

  final Map<String, dynamic> box;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${box['note']}",
                style: textStyle.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor3
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: 2.h),
              box['note'].contains('نقل')
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${'from'.tr} : ${box['from']}",
                          style: textStyle.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor3
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "${'to'.tr} : ${box['to']}",
                          style: textStyle.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor3
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      "${box['boxName']}",
                      style: textStyle.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor3
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
            ],
          ),
          Spacer(),
          Container(
            width: 60.w,
            height: 70.h,
            decoration: BoxDecoration(
              color: box['note'] == 'نقل رصيد'
                  ? AppColors.customOrange3
                  : box['note'] == 'سحب رصيد'
                      ? AppColors.redColor
                      : AppColors.customGreen1,
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
              children: [
                Text(
                  NumberFormat('#,###').format(
                    int.parse(box['amount'].toString()),
                  ),
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
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
