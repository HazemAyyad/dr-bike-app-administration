import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import 'delivered_purchases_dialog.dart';

class ReturnPurchasesList extends StatelessWidget {
  const ReturnPurchasesList({
    Key? key,
    required this.month,
    required this.bills,
  }) : super(key: key);

  final String month;
  final List bills;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          // separator عنوان الشهر
          Row(
            children: [
              Text(
                month,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                    ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Container(
            height: 1.h,
            width: double.infinity,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 10.h),
          // عرض العناصر
          ...bills.map(
            (bill) => GestureDetector(
              onTap: () {
                Get.dialog(
                  DeliveredPurchasesDialog(
                    billId: bill.id.toString(),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5.h),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(32),
                      blurRadius: 5.r,
                      spreadRadius: 2.r,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 5.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'sellerName1'.tr}: ${bill.seller.name}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: ThemeService.isDark.value
                                        ? AppColors.customGreyColor7
                                        : AppColors.customGreyColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15.sp,
                                  ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              "${'productName'.tr}: ${bill.items.first.productName}",
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: ThemeService.isDark.value
                                        ? AppColors.customGreyColor7
                                        : AppColors.customGreyColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15.sp,
                                  ),
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${'quantity'.tr}: ${bill.items.first.quantity.toString()}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: ThemeService.isDark.value
                                              ? AppColors.customGreyColor7
                                              : AppColors.customGreyColor,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15.sp,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${'price'.tr}: ${NumberFormat("#,###").format(double.parse(bill.items.first.price.toString()))}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: ThemeService.isDark.value
                                              ? AppColors.customGreyColor7
                                              : AppColors.customGreyColor,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15.sp,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      width: 65.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        color: AppColors.graywhiteColor,
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
                      child: Center(
                        child: Text(
                          '${'total'.tr} ${NumberFormat("#,###").format(double.parse(bill.total))}',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.customGreyColor,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
