import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

/// Enter / update recipient phone before Shiply handover.
class SalesOrderShiplyPhoneDialog extends StatefulWidget {
  const SalesOrderShiplyPhoneDialog({
    Key? key,
    required this.orderId,
    required this.controller,
    required this.selection,
  }) : super(key: key);

  final int orderId;
  final SalesOrdersController controller;
  final ShiplyPartnerSelection selection;

  @override
  State<SalesOrderShiplyPhoneDialog> createState() =>
      _SalesOrderShiplyPhoneDialogState();
}

class _SalesOrderShiplyPhoneDialogState
    extends State<SalesOrderShiplyPhoneDialog> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.selection.partner.phone.trim(),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SalesOrdersController.surfaceGray,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'salesOrderShiplyPhoneTitle'.tr,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'salesOrderShiplyPhoneSubtitle'.trParams({
                'name': widget.selection.partner.name,
              }),
              style: TextStyle(
                color: SalesOrdersController.textSecondary,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                labelText: 'phoneNumber'.tr,
                hintText: '0599999999',
                labelStyle:
                    const TextStyle(color: SalesOrdersController.textSecondary),
                filled: true,
                fillColor: SalesOrdersController.cardGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide:
                      const BorderSide(color: SalesOrdersController.borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide:
                      const BorderSide(color: SalesOrdersController.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: SalesOrdersController.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'salesOrderShiplyPhoneHint'.tr,
              style: TextStyle(
                fontSize: 11.sp,
                color: SalesOrdersController.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),
            Obx(() {
              final busy = widget.controller.isSubmitting.value;
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
                              final ok =
                                  await widget.controller.updatePartnerPhoneAndOrder(
                                orderId: widget.orderId,
                                selection: widget.selection,
                                phone: _phoneController.text,
                              );
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
    );
  }
}
