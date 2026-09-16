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
      final grandTotal = itemsTotal + deliveryFee;
      final quotedDeliveryFee = orders.shiplyQuotedDeliveryFee.value;

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: SalesOrdersController.cardGray,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: SalesOrdersController.borderGray),
        ),
        child: Column(
          children: [
            _line('سعر المنتجات قبل الخصم', subtotal),
            if (discount > 0) _line('discount'.tr, -discount, muted: true),
            _line('صافي سعر الطلب', itemsTotal),
            _line('رسوم التوصيل على الزبون', deliveryFee),
            Divider(height: 14.h, color: SalesOrdersController.borderGray),
            TextField(
              controller: orders.deliveryFeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => orders.onDeliveryFeeChanged(),
              decoration: const InputDecoration(
                labelText: 'رسوم التوصيل المحمّلة على الزبون',
                helperText:
                    'تُضاف إلى صافي سعر الطلب لتكوين المبلغ المطلوب من الزبون.',
                suffixText: '₪',
                border: OutlineInputBorder(),
              ),
            ),
            if (quotedDeliveryFee != null) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18.sp,
                      color: const Color(0xFF1E3A5F),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        'السعر التقديري حسب Shiply للعنوان المختار',
                        style: TextStyle(
                          color: const Color(0xFF1E3A5F),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${quotedDeliveryFee.toStringAsFixed(2)} ₪',
                      style: TextStyle(
                        color: const Color(0xFF1E3A5F),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: SalesOrdersController.borderGray),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                dense: true,
                value: orders.priceIncludesDelivery.value,
                onChanged: deliveryFee > 0
                    ? (value) =>
                        orders.priceIncludesDelivery.value = value ?? false
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF2563EB),
                title: Text(
                  'salesOrderPriceIncludesDelivery'.tr,
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  deliveryFee > 0
                      ? 'salesOrderPriceIncludesDeliveryHint'.tr
                      : 'أدخل رسوم التوصيل أولاً لتفعيل هذا الخيار.',
                  style: TextStyle(
                    color: SalesOrdersController.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            _line('إجمالي المطلوب من الزبون', grandTotal, bold: true),
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
