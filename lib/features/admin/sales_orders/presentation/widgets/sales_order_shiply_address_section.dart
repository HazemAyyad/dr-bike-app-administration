import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

/// Shiply city + village + street + delivery fee for sales orders.
class SalesOrderShiplyAddressSection extends GetView<SalesOrdersController> {
  const SalesOrderShiplyAddressSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cities = controller.shiplyCities;
      if (cities.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            'shiplyAddressesEmpty'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: SalesOrdersController.textSecondary,
            ),
          ),
        );
      }

      final villages = controller.selectedShiplyVillages;
      final closedLabel = 'shiplyVillageClosed'.tr;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'salesOrderShiplyCity'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: SalesOrdersController.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<int>(
            value: controller.selectedShiplyCityId.value,
            decoration: _fieldDecoration(),
            hint: Text('city'.tr),
            items: cities
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ),
                )
                .toList(),
            onChanged: controller.onShiplyCityChanged,
          ),
          SizedBox(height: 12.h),
          Text(
            'salesOrderShiplyVillage'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: SalesOrdersController.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<int>(
            value: controller.selectedShiplyVillageId.value,
            decoration: _fieldDecoration(),
            hint: Text('salesOrderShiplyVillage'.tr),
            items: villages
                .map(
                  (v) => DropdownMenuItem(
                    value: v.id,
                    enabled: !v.isClosed,
                    child: Text(v.displayLabel(closedLabel)),
                  ),
                )
                .toList(),
            onChanged: villages.isEmpty ? null : controller.onShiplyVillageChanged,
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller.customerAddressController,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              labelText: 'salesOrderStreetAddress'.tr,
              labelStyle: const TextStyle(color: SalesOrdersController.textSecondary),
              filled: true,
              fillColor: SalesOrdersController.cardGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller.deliveryFeeController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              labelText: 'salesOrderDeliveryFee'.tr,
              labelStyle: const TextStyle(color: SalesOrdersController.textSecondary),
              filled: true,
              fillColor: SalesOrdersController.cardGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onChanged: (_) => controller.onDeliveryFeeChanged(),
          ),
        ],
      );
    });
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: SalesOrdersController.cardGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }
}
