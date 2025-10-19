import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../controllers/debts_controller.dart';

class UserAccount extends GetView<DebtsController> {
  const UserAccount({
    Key? key,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  final String userName;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 72.h,
            // width: 279.w,
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Image.asset(
                      AssetsManager.cashIcon,
                      width: 30.w,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
                    Text(
                      'balance'.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.primaryColor
                                : AppColors.secondaryColor,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                GetBuilder<DebtsController>(
                  builder: (controller) => Flexible(
                    child: Text(
                      controller.dataService.userTransactionsDataModel.value ==
                              null
                          ? '0.00 ${'currency'.tr}'
                          : '${NumberFormat("#,###").format(double.parse(controller.dataService.userTransactionsDataModel.value!.customerBalance))} ${'currency'.tr}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: double.parse(controller
                                            .dataService
                                            .userTransactionsDataModel
                                            .value
                                            ?.customerBalance ??
                                        '0') <
                                    0
                                ? Colors.red
                                : Colors.green,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Column(
          children: [
            GestureDetector(
              onTap: () {
                controller.downloadReport(
                  customerId: userId,
                  customerName: userName,
                  context: context,
                  isShared: true,
                );
              },
              child: Container(
                height: 45.h,
                width: 45.w,
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_outlined,
                  size: 30.h,
                  color: ThemeService.isDark.value
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'Share'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                  ),
            ),
          ],
        ),
        SizedBox(width: 10.w),
        Column(
          children: [
            GestureDetector(
              onTap: () {
                controller.downloadReport(
                  customerId: userId,
                  customerName: userName,
                  context: context,
                );
              },
              child: Container(
                height: 45.h,
                width: 45.w,
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 30.h,
                  color: ThemeService.isDark.value
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'report'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
