import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

/// Bottom sheet بسيط لاختيار مصدر الوسائط (كاميرا أو معرض).
Future<String?> showSalesOrderMediaSourceSheet() {
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
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: SalesOrdersController.borderGray,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'salesOrderUploadMedia'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: SalesOrdersController.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'salesOrderMediaSourceHint'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: SalesOrdersController.textSecondary,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _MediaSourceTile(
                      icon: Icons.photo_camera_outlined,
                      label: 'camera'.tr,
                      onTap: () => Get.back(result: 'camera'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _MediaSourceTile(
                      icon: Icons.photo_library_outlined,
                      label: 'gallery'.tr,
                      onTap: () => Get.back(result: 'gallery'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
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

/// اختيار صورة أو فيديو من الكاميرا.
Future<String?> showSalesOrderCameraTypeSheet() {
  return Get.bottomSheet<String>(
    Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: SalesOrdersController.borderGray,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'camera'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: SalesOrdersController.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _MediaSourceTile(
                      icon: Icons.image_outlined,
                      label: 'takeImage'.tr,
                      compact: true,
                      onTap: () => Get.back(result: 'camera_image'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _MediaSourceTile(
                      icon: Icons.videocam_outlined,
                      label: 'takeVideo'.tr,
                      compact: true,
                      onTap: () => Get.back(result: 'camera_video'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
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

class _MediaSourceTile extends StatelessWidget {
  const _MediaSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 16.h : 22.h,
            horizontal: 8.w,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: SalesOrdersController.borderGray),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 28.sp : 34.sp,
                color: SalesOrdersController.textPrimary,
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 12.sp : 13.sp,
                  fontWeight: FontWeight.w600,
                  color: SalesOrdersController.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
