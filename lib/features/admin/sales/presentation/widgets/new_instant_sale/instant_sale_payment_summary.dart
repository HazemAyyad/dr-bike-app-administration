import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/sales_amount_format.dart';

/// يعرض إجمالي الفاتورة والمدفوع والمتبقي أثناء إنشاء بيع فوري.
class InstantSalePaymentSummary extends GetView<SalesController> {
  const InstantSalePaymentSummary({
    Key? key,
    this.extraTotal = 0,
  }) : super(key: key);

  /// Useful for flows that add a fee outside `SalesController.totalCost` (e.g. sales orders delivery fee).
  final double extraTotal;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.totalCost.value + extraTotal;
      final paid = controller.instantSalePaidAmount.value;
      final remaining = (total - paid).clamp(0, double.infinity).toDouble();

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            _row('totalBill'.tr, total, bold: true),
            SizedBox(height: 8.h),
            _row('paidAmount'.tr, paid, color: Colors.green.shade700),
            SizedBox(height: 6.h),
            _row(
              'remainingAmount'.tr,
              remaining,
              color: remaining > 0.01
                  ? Colors.orange.shade800
                  : Colors.grey.shade700,
              bold: remaining > 0.01,
            ),
          ],
        ),
      );
    });
  }

  Widget _row(
    String label,
    double amount, {
    Color? color,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          SalesAmountFormat.display(amount),
          style: TextStyle(
            fontSize: bold ? 16.sp : 14.sp,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}
