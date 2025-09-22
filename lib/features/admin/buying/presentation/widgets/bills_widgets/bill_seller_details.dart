import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/bills_controller.dart';

class BillSellerDetails extends GetView<BillsController> {
  const BillSellerDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 30.w),
          height: 1.h,
          width: double.infinity,
          color: AppColors.primaryColor,
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '${'sellerName'.tr} : ${controller.billDetails!.sellerName}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
              ),
              Text(
                '${'date'.tr} : ${controller.billDetails!.createdAt}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
              ),
              Text(
                '${'total'.tr} : ${NumberFormat("#,###").format(double.parse(controller.billDetails!.totalBill))}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
