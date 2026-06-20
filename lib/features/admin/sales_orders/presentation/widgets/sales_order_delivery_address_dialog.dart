import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

/// Simple street address capture for non-Shiply delivery handover.
class SalesOrderDeliveryAddressDialog extends StatelessWidget {
  const SalesOrderDeliveryAddressDialog({
    Key? key,
    required this.orderId,
    required this.controller,
  }) : super(key: key);

  final int orderId;
  final SalesOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SalesOrdersController.surfaceGray,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'salesOrderDeliveryAddressTitle'.tr,
                style: TextStyle(
                  color: SalesOrdersController.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'salesOrderDeliveryAddressSubtitle'.tr,
                style: TextStyle(
                  color: SalesOrdersController.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: controller.customerAddressController,
                maxLines: 3,
                style: TextStyle(
                  color: SalesOrdersController.textPrimary,
                  fontSize: 14.sp,
                ),
                decoration: InputDecoration(
                  labelText: 'salesOrderStreetAddress'.tr,
                  labelStyle:
                      const TextStyle(color: SalesOrdersController.textSecondary),
                  filled: true,
                  fillColor: SalesOrdersController.cardGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Obx(() {
                final busy = controller.isSubmitting.value;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => Get.back(result: false),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final ok = await controller
                                    .saveDeliveryAddressForOrder(orderId);
                                if (ok) Get.back(result: true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SalesOrdersController.textPrimary,
                          foregroundColor: SalesOrdersController.cardGray,
                        ),
                        child: busy
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SalesOrdersController.cardGray,
                                ),
                              )
                            : Text('saveAndContinue'.tr),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
