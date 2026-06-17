import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

/// اختيار مدينة التوصيل — اختياري عند الإنشاء/التعديل.
class SalesOrderCitySection extends GetView<SalesOrdersController> {
  const SalesOrderCitySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cities = controller.cities;
      if (cities.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'salesOrderDeliveryCity'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: SalesOrdersController.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'salesOrderCityHint'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              color: SalesOrdersController.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<int>(
            value: controller.selectedCityId.value,
            decoration: InputDecoration(
              filled: true,
              fillColor: SalesOrdersController.cardGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            hint: Text('city'.tr),
            items: cities
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.deliveryFee != null
                          ? '${c.nameAr} (${c.deliveryFee!.toStringAsFixed(0)} ₪)'
                          : c.nameAr,
                    ),
                  ),
                )
                .toList(),
            onChanged: controller.onDeliveryCityChanged,
          ),
        ],
      );
    });
  }
}
