import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

/// Visible when Shiply sandbox / test mode is active.
class SalesOrderShiplySandboxBadge extends StatelessWidget {
  const SalesOrderShiplySandboxBadge({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SalesOrdersController controller;

  static const _amberBg = Color(0xFFFFF8E1);
  static const _amberBorder = Color(0xFFFFCC80);
  static const _amberText = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.shiplyIsSandboxMode.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _amberBg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _amberBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.science_outlined, size: 18.sp, color: _amberText),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'shiplySandboxAccountBadge'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _amberText,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
