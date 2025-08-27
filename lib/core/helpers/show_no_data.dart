import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../utils/app_colors.dart';

class ShowNoData extends StatelessWidget {
  const ShowNoData({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
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
            'noData'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.graywhiteColor,
                ),
          ),
        ],
      ),
    );
  }
}
