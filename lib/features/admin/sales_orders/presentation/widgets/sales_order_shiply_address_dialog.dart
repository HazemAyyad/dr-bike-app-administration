import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';
import 'sales_order_shiply_address_fields.dart';

/// Modal to capture delivery address before handover.
class SalesOrderShiplyAddressDialog extends StatelessWidget {
  const SalesOrderShiplyAddressDialog({
    Key? key,
    required this.orderId,
    required this.controller,
    required this.parcelPrice,
    this.showShiplyBranding = true,
  }) : super(key: key);

  final int orderId;
  final SalesOrdersController controller;
  final double parcelPrice;
  final bool showShiplyBranding;

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
                showShiplyBranding
                    ? 'salesOrderShiplyAddressTitle'.tr
                    : 'salesOrderCarrierAddressTitle'.tr,
                style: TextStyle(
                  color: SalesOrdersController.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                showShiplyBranding
                    ? 'salesOrderShiplyAddressSubtitle'.tr
                    : 'salesOrderCarrierAddressSubtitle'.tr,
                style: TextStyle(
                  color: SalesOrdersController.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 16.h),
              SalesOrderShiplyAddressFields(
                controller: controller,
                parcelPriceForFee: parcelPrice,
                showShiplyBranding: showShiplyBranding,
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
                                final ok = showShiplyBranding
                                    ? await controller
                                        .saveShiplyAddressForOrder(orderId)
                                    : await controller
                                        .saveCarrierAddressForOrder(orderId);
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
