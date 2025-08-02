import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../controllers/debts_controller.dart';
import 'show_user_transactions.dart';

Widget showDebtsWidget(DebtsController controller, BuildContext context) {
  return Obx(
    () {
      if (controller.isDebtsWeOweLoading.value) {
        return SliverToBoxAdapter(
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        );
      } else if (controller.filteredDebts.isEmpty) {
        return SliverToBoxAdapter(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 100.h,
                  color: AppColors.graywhiteColor,
                ),
                SizedBox(height: 10.h),
                Text(
                  'noDebts'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.graywhiteColor,
                      ),
                ),
                SizedBox(height: 150.h),
              ],
            ),
          ),
        );
      }

      return SliverList.builder(
        itemCount: controller.filteredDebts.length,
        itemBuilder: (context, index) {
          final reversedIndex = controller.filteredDebts.length - 1 - index;
          final debt = controller.filteredDebts[reversedIndex];
          final today = DateTime.now();
          final inputStartDate = debt.debtCreatedAt;
          final startDateDifference = today.difference(inputStartDate).inDays;
          final inputEndDate = debt.dueDate;
          final endDateDifference = today.difference(inputEndDate).inDays;

          return Column(
            children: [
              SizedBox(height: index == 0 ? 5.h : 0.h),
              GestureDetector(
                onTap: () {
                  controller
                      .getUserTransactionsData(debt.customerId.toString());
                  showUserTransactions(context, controller, debt);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        child: SizedBox(
                          height: 30.h,
                          child: Image.asset(
                            AssetsManger.userIconNew,
                            fit: BoxFit.contain,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  debt.customerName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: ThemeService.isDark.value
                                            ? Colors.white
                                            : AppColors.secondaryColor,
                                      ),
                                ),
                                Text(
                                  '${NumberFormat("#,###0.00").format(double.parse(debt.total))} ${'currency'.tr}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        decoration: debt.status == 'paid'
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        decorationColor:
                                            controller.currentTab.value == 0
                                                ? Colors.red
                                                : Colors.green,
                                        decorationThickness: 1.5,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: controller.currentTab.value == 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${'since'.tr} ${startDateDifference.toString()} ${startDateDifference > 10 ? 'days'.tr : 'dayss'.tr}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.customGreyColor2,
                                      ),
                                ),
                                Text(
                                  "${'remaining'.tr} ${endDateDifference.toString()} ${endDateDifference > 10 ? 'days'.tr : 'dayss'.tr}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.customGreyColor2,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            GestureDetector(
                              onTap: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'Dismiss',
                                  barrierColor: Colors.black.withAlpha(128),
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  pageBuilder: (context, anim1, anim2) {
                                    return FullScreenZoomImage(
                                      imageUrl: debt.receiptImage,
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: debt.receiptImage,
                                fit: BoxFit.cover,
                                height: 50.h,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryColor),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                  height: index == controller.filteredDebts.length - 1
                      ? 60.h
                      : 0.h),
            ],
          );
        },
      );
    },
  );
}
