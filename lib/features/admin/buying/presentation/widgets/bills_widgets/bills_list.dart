import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/bills_models/bills_model.dart';
import '../../controllers/bills_controller.dart';

class BillsList extends GetView<BillsController> {
  const BillsList({
    Key? key,
    required this.bills,
    required this.month,
    required this.page,
  }) : super(key: key);

  final List<BillDataModel> bills;
  final String month;
  final String page;
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
                controller.getBillDetails(
                  context: context,
                  billId: bill.id.toString(),
                );
                Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: page);
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
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        // vertical: 10.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'billNumber'.tr}: ${bill.id.toString()}',
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
                          SizedBox(height: 10.h),
                          Text(
                            "${'sellerName1'.tr}: ${bill.seller.toString()}",
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
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      width: 65.w,
                      height: 60.h,
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
