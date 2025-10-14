import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/follow_up_controller.dart';
import 'cancel_dialog.dart';
import 'contact_dialog.dart';

class FollowUpWidget extends StatelessWidget {
  const FollowUpWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FollowUpController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.currentTab.value == 0 &&
            controller.initialFollowupsFilterList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 1 &&
            controller.informFollowupsFilterList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 2 &&
            controller.finishAndAgreementFollowupsFilterList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        if (controller.currentTab.value == 3 &&
            controller.archivedFollowupsFilterList.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final followup = controller.currentTab.value == 0
                  ? controller.initialFollowupsFilterList.reversed
                      .toList()[index]
                  : controller.currentTab.value == 1
                      ? controller.informFollowupsFilterList.reversed
                          .toList()[index]
                      : controller.currentTab.value == 2
                          ? controller
                              .finishAndAgreementFollowupsFilterList.reversed
                              .toList()[index]
                          : controller.archivedFollowupsFilterList.reversed
                              .toList()[index];
              return GestureDetector(
                onTap: () => controller.getFollowUpDetails(
                  followupId: followup.id.toString(),
                ),
                child: Container(
                  // height: 90.h,
                  margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 5.h,
                            horizontal: 10.w,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5.h),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      followup.customerName.isNotEmpty
                                          ? followup.customerName
                                          : followup.sellerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: ThemeService.isDark.value
                                                ? AppColors.customGreyColor6
                                                : AppColors.customGreyColor5,
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  GestureDetector(
                                    onTap: () {
                                      Get.dialog(
                                        ContactDialog(
                                          phone:
                                              followup.customerPhone.isNotEmpty
                                                  ? followup.customerPhone
                                                  : followup.sellerPhone,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.phone_outlined,
                                      size: 23.sp,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    showData(followup.createdAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          color: ThemeService.isDark.value
                                              ? AppColors.customGreyColor6
                                              : AppColors.customGreyColor5,
                                        ),
                                  ),
                                  SizedBox(width: 10.w),
                                  if (controller.currentTab.value != 3)
                                    GestureDetector(
                                      onTap: () => Get.dialog(
                                        CancelDialog(
                                            followupId: followup.id.toString()),
                                      ),
                                      child: Container(
                                        height: 30.h,
                                        width: 80.w,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 5.w),
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 5.w),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.redColor),
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(30.r),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'cancelFollowUp'.tr,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.redColor,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (controller.currentTab.value == 3)
                                    Container(
                                      height: 30.h,
                                      width: 80.w,
                                      decoration: BoxDecoration(
                                        color: followup.followupStatus ==
                                                'delivered'
                                            ? AppColors.customGreen1
                                            : AppColors.redColor,
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Center(
                                        child: Text(
                                          followup.followupStatus == 'delivered'
                                              ? 'sale_completed'.tr
                                              : 'sale_rejected'.tr,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.whiteColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                followup.productName,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: controller.currentTab.value == 0
                ? controller.initialFollowupsFilterList.length
                : controller.currentTab.value == 1
                    ? controller.informFollowupsFilterList.length
                    : controller.currentTab.value == 2
                        ? controller
                            .finishAndAgreementFollowupsFilterList.length
                        : controller.archivedFollowupsFilterList.length,
          ),
        );
      },
    );
  }
}
