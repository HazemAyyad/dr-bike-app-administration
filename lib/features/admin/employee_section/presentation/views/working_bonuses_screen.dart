import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

import '../../../../../core/utils/app_colors.dart';

class PointsTable extends StatelessWidget {
  const PointsTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TableRow buildRow(List<String> cells, {bool isHeader = false}) {
      return TableRow(
        children: cells.map(
          (cell) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                cell.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight:
                          isHeader ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15.sp,
                    ),
              ),
            );
          },
        ).toList(),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'workingHoursBonuses',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor, width: 1.w),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11.r),
                  topRight: Radius.circular(11.r),
                ),
              ),
              child: Text(
                'penalties'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor, width: 1.5.w),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(11.r),
                  bottomRight: Radius.circular(11.r),
                ),
              ),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: AppColors.primaryColor, width: 1.w),
                ),
                children: [
                  buildRow(["overtimeTime", "rewardPoints"], isHeader: true),
                  buildRow(["1", "20-"]),
                  buildRow(["5", "100-"]),
                  buildRow(["15", "150-"]),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // جدول المكافآت
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor, width: 1.w),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11.r),
                  topRight: Radius.circular(11.r),
                ),
              ),
              child: Text(
                'rewards'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor, width: 1.5.w),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(11.r),
                  bottomRight: Radius.circular(11.r),
                ),
              ),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: AppColors.primaryColor, width: 1.w),
                ),
                children: [
                  buildRow(["penaltyTime", "addedPoints"], isHeader: true),
                  buildRow(["5 - 0", "20"]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
