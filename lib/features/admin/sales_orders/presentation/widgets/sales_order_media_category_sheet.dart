import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

Future<String?> showSalesOrderMediaCategorySheet() {
  const categories = [
    'items_group',
    'packaged',
    'testing',
    'document',
    'general',
  ];

  return Get.bottomSheet<String>(
    Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'salesOrderMediaCategoryTitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: SalesOrdersController.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              ...categories.map((category) {
                final labelKey = 'salesOrderMediaCategory_$category';
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: category),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SalesOrdersController.textPrimary,
                      side: const BorderSide(
                        color: SalesOrdersController.borderGray,
                      ),
                      backgroundColor: SalesOrdersController.cardGray,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(labelKey.tr),
                  ),
                );
              }),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    backgroundColor: SalesOrdersController.cardGray,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
  );
}
