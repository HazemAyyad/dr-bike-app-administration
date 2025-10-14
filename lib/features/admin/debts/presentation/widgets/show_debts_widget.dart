import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../data/models/debts_we_owe_model.dart';
import '../controllers/debts_controller.dart';
import 'show_user_transactions.dart';

class ShowDebtsWidget extends GetView<DebtsController> {
  const ShowDebtsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.isDebtsWeOweLoading.value) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (controller.filteredDebts.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }

        return SliverList.builder(
          itemCount: controller.filteredDebts.length,
          itemBuilder: (context, index) {
            final reversedIndex = controller.filteredDebts.length - 1 - index;
            final debt = controller.filteredDebts[reversedIndex] as DebtsWeOwe;
            final today = DateTime.now();
            final daysPassed = today.difference(debt.debtCreatedAt).inDays;
            final daysLeft = debt.dueDate.difference(today).inDays;

            return Column(
              children: [
                SizedBox(height: index == 0 ? 5.h : 0.h),
                InkWell(
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  onTap: () {
                    controller.customerId.value = debt.customerId.toString();
                    controller.sellerId.value = debt.sellerId.toString();
                    controller.getUserTransactionsData(
                      debt.customerId.toString(),
                      debt.sellerId.toString(),
                    );
                    Get.bottomSheet(
                      ShowUserTransactions(
                        debt: debt,
                        userId: debt.customerName.isNotEmpty
                            ? debt.customerId.toString()
                            : debt.sellerId.toString(),
                        isSeller: debt.customerName.isNotEmpty ? false : true,
                      ),
                      ignoreSafeArea: false,
                      isScrollControlled: true,
                      backgroundColor: ThemeService.isDark.value
                          ? AppColors.darkColor
                          : Colors.white,
                    );
                  },
                  child:
                      // Container(
                      // margin: EdgeInsets.only(bottom: 10.h),
                      // padding:
                      //     EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      // decoration: BoxDecoration(
                      //   color: ThemeService.isDark.value
                      //       ? AppColors.customGreyColor
                      //       : AppColors.whiteColor2,
                      //   borderRadius: BorderRadius.circular(16.r),
                      // ),
                      // child:
                      Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        child: SizedBox(
                          height: 30.h,
                          child: Image.asset(
                            AssetsManager.userIconNew,
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
                                Flexible(
                                  child: Text(
                                    debt.customerName.isNotEmpty
                                        ? debt.customerName
                                        : debt.sellerName,
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
                                ),
                                Text(showData(debt.debtCreatedAt)),
                                Flexible(
                                  child: Text(
                                    '${NumberFormat("#,###").format(double.parse(debt.total))} ${'currency'.tr}',
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
                                          color:
                                              controller.currentTab.value == 0
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${'since'.tr} ${daysPassed.toString()} ${daysPassed > 10 || daysLeft < 0 ? 'days'.tr : 'dayss'.tr}",
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
                                  debt.status == 'paid'
                                      ? 'ended'.tr
                                      : "${'remaining'.tr} ${daysLeft.toString()} ${daysLeft > 10 || daysLeft < 0 ? 'days'.tr : 'dayss'.tr}",
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
                            Row(
                              children: [
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
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  height: 1.h,
                  color: AppColors.customGreyColor2,
                ),
                SizedBox(
                  height:
                      index == controller.filteredDebts.length - 1 ? 60.h : 0.h,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
