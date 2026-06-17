import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';
import 'sales_order_shiply_address_fields.dart';

/// Modal to capture Shiply address before handover.
class SalesOrderShiplyAddressDialog extends StatelessWidget {
  const SalesOrderShiplyAddressDialog({
    Key? key,
    required this.orderId,
    required this.controller,
    required this.parcelPrice,
  }) : super(key: key);

  final int orderId;
  final SalesOrdersController controller;
  final double parcelPrice;

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
                'salesOrderShiplyAddressTitle'.tr,
                style: TextStyle(
                  color: SalesOrdersController.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'salesOrderShiplyAddressSubtitle'.tr,
                style: TextStyle(
                  color: SalesOrdersController.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 16.h),
              SalesOrderShiplyAddressFields(
                controller: controller,
                parcelPriceForFee: parcelPrice,
              ),
              SizedBox(height: 20.h),
              Obx(() {
                final busy = controller.isSubmitting.value;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SalesOrdersController.textPrimary,
                          side: const BorderSide(
                            color: SalesOrdersController.borderGray,
                          ),
                          backgroundColor: SalesOrdersController.cardGray,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
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
                                    .saveShiplyAddressForOrder(orderId);
                                if (ok) Get.back(result: true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SalesOrdersController.textPrimary,
                          foregroundColor: SalesOrdersController.cardGray,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
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
