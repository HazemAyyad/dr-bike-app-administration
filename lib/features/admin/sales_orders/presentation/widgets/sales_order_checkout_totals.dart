import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../controllers/sales_orders_controller.dart';

/// ملخص مالي لمراجعة الطلبية (أصناف + توصيل + خصم).
class SalesOrderCheckoutTotals extends StatelessWidget {
  const SalesOrderCheckoutTotals({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orders = Get.find<SalesOrdersController>();
    final sales = Get.find<SalesController>();

    return Obx(() {
      final _ = sales.cartRevision.value;
      final itemsTotal = sales.totalCost.value;
      final deliveryFee = orders.selectedCityDeliveryFee;
      final discount = SalesAmountFormat.parse(sales.discountController.text);
      final subtotal = itemsTotal + discount;
      final calculatedTotal = itemsTotal + deliveryFee;
      final grandTotal = orders.manualTotal.value ?? itemsTotal + deliveryFee;

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: SalesOrdersController.cardGray,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: SalesOrdersController.borderGray),
        ),
        child: Column(
          children: [
            _line('subtotal'.tr, subtotal),
            if (discount > 0) _line('discount'.tr, -discount, muted: true),
            if (deliveryFee > 0) _line('salesOrderDeliveryFee'.tr, deliveryFee),
            _line('salesOrderCalculatedTotal'.tr, calculatedTotal),
            Divider(height: 14.h, color: SalesOrdersController.borderGray),
            TextField(
              controller: orders.deliveryFeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => orders.onDeliveryFeeChanged(),
              decoration: InputDecoration(
                labelText: 'salesOrderDeliveryFeeInput'.tr,
                suffixText: '₪',
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: orders.totalController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: orders.onTotalChanged,
              decoration: InputDecoration(
                labelText: 'salesOrderEditableTotal'.tr,
                suffixText: '₪',
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8.h),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: orders.priceIncludesDelivery.value,
              onChanged: (value) =>
                  orders.priceIncludesDelivery.value = value ?? false,
              title: Text('salesOrderPriceIncludesDelivery'.tr),
              subtitle: Text('salesOrderPriceIncludesDeliveryHint'.tr),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            _line('total'.tr, grandTotal, bold: true),
          ],
        ),
      );
    });
  }

  Widget _line(String label, double amount,
      {bool bold = false, bool muted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 13.sp : 12.sp,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: muted
                    ? SalesOrdersController.textSecondary
                    : SalesOrdersController.textPrimary,
              ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)} ₪',
            style: TextStyle(
              fontSize: bold ? 14.sp : 12.sp,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: muted
                  ? SalesOrdersController.textSecondary
                  : SalesOrdersController.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
