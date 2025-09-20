import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../data/models/my_orders_model_model.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({Key? key, required this.order}) : super(key: key);

  final MyOrdersModel order;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                showData(order.createdAt),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.customGreyColor5,
                    ),
              ),
              Flexible(
                child: SizedBox(
                  width: 140.w,
                  child: Text(
                    order.loanValue.isNotEmpty
                        ? '${order.loanValue} ${'currency'.tr}'
                        : order.extraWorkHours.isNotEmpty
                            ? '${order.extraWorkHours} ${'hours'.tr}'
                            : '${order.overtimeValue} ${'hours'.tr}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.customGreyColor5,
                        ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                width: 100.w,
                // width: Get.locale!.languageCode == 'en' ? 90.w : 70.w,
                decoration: BoxDecoration(
                  color: order.status == 'pending'
                      ? AppColors.customOrange2
                      : order.status == 'approved'
                          ? AppColors.customGreen2
                          : Colors.red,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Center(
                  child: Text(
                    order.status.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          const Divider(color: AppColors.customGreyColor2, thickness: 1),
        ],
      ),
    );
  }
}
