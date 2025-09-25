import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/check_model.dart';
import 'check_details.dart';

class ViewChecksWidget extends StatelessWidget {
  final CheckModel check;
  final bool? shadowed;
  final int? currentTab;
  final bool type;
  const ViewChecksWidget({
    Key? key,
    required this.check,
    this.shadowed = true,
    this.currentTab,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.dialog(CheckDetails(check: check, type: type)),
      child: Container(
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
                    offset: const Offset(0, 0),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
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
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "${NumberFormat('#,###').format(double.parse(check.total))} ${check.currency}",
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
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${'checkNumber'.tr} : ${check.checkId}",
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                        ),
                        if (currentTab == 0) SizedBox(height: 10.h),
                        Text(
                          "${'due_date'.tr} : ${showData(check.dueDate)}",
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                        ),
                        if (currentTab == 1)
                          SizedBox(
                            width: 200.w,
                            child: Text(
                              check.customer != null
                                  ? check.customer!.name
                                  : check.seller != null
                                      ? check.seller!.name
                                      : check.fromCustomer != null
                                          ? check.toCustomer != null
                                              ? '${'from'.tr} ${check.fromCustomer!.name} ${'to'.tr} ${check.toCustomer!.name}'
                                              : '${'from'.tr} ${check.fromCustomer!.name} ${'to'.tr} ${check.toSeller!.name}'
                                          : check.toSeller != null
                                              ? '${'from'.tr} ${check.fromSeller!.name} ${'to'.tr} ${check.toSeller!.name}'
                                              : '${'from'.tr} ${check.fromSeller!.name} ${'to'.tr} ${check.toCustomer!.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    // color: Colors.grey.withAlpha(500),
                                  ),
                            ),
                          ),
                        if (currentTab == 2)
                          Text(
                            check.customer != null
                                ? check.customer!.name
                                : check.seller != null
                                    ? check.seller!.name
                                    : check.fromCustomer != null
                                        ? check.fromCustomer!.name
                                        : check.fromSeller != null
                                            ? check.fromSeller!.name
                                            : '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            currentTab != 2
                ? Container(
                    width: 60.w,
                    height: 75.h,
                    decoration: BoxDecoration(
                      color: check.dueDate.difference(DateTime.now()).inDays > 5
                          ? AppColors.customGreen1
                          : check.dueDate.difference(DateTime.now()).inDays > 0
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
                          check.dueDate
                              .difference(DateTime.now())
                              .inDays
                              .toString(),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                        ),
                        Text(
                          check.dueDate.difference(DateTime.now()).inDays >
                                      10 ||
                                  check.dueDate
                                          .difference(DateTime.now())
                                          .inDays <
                                      -10
                              ? 'days'.tr
                              : 'dayss'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: 60.w,
                    height: 75.h,
                    decoration: BoxDecoration(
                      color: check.status == 'cashed' ||
                              check.status == 'cashed_to_box'
                          ? AppColors.customGreen1
                          : check.status != 'cancelled'
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
                          'check'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          check.status == 'cashed' ||
                                  check.status == 'cashed_to_box'
                              ? 'cashed'.tr
                              : check.status == 'cancelled'
                                  ? 'rejectedd'.tr
                                  : 'reference'.tr,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
