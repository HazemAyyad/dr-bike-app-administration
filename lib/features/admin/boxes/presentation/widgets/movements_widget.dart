import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../domain/entity/all_boxes_logs_entity.dart';

class MovementsWidget extends StatelessWidget {
  const MovementsWidget({Key? key, required this.box}) : super(key: key);

  final BoxLog box;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                box.type! == 'transfer'
                    ? 'transferBalance'.tr
                    : 'addOrTransferBalance'.tr,
                style: textStyle.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor3
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: 2.h),
              box.fromBox != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${'from'.tr} : ${box.fromBox!.name}",
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
                          "${'to'.tr} : ${box.toBox!.name}",
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
                      box.box?.name ?? '',
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
        ),
        const Spacer(),
        Container(
          width: 60.w,
          height: 70.h,
          decoration: BoxDecoration(
            color: box.type == 'transfer'
                ? AppColors.customOrange3
                : box.type != 'add'
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
                NumberFormat('#,###').format(box.value),
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
    );
  }
}
