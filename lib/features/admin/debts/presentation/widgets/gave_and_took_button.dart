import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/debts_controller.dart';
import 'creat_debts.dart';

Padding gaveAndTookButton(BuildContext context) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 24.w),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              createDebts(
                context,
                'create_debt_for_us',
                'gave',
                Colors.red,
                Get.find<DebtsController>(),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 30.h, left: 15.w, right: 15.w),
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  'gave'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              createDebts(
                context,
                'create_debt_on_us',
                'took',
                Colors.green,
                Get.find<DebtsController>(),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 30.h, left: 15.w, right: 15.w),
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  'took'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        )
      ],
    ),
  );
}
