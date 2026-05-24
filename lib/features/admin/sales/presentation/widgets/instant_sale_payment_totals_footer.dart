import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../utils/sales_amount_format.dart';

/// تذييل يعرض الإجمالي والمدفوع والمتبقي (فاتورة / قائمة مبيعات).
class InstantSalePaymentTotalsFooter extends StatelessWidget {
  const InstantSalePaymentTotalsFooter({
    Key? key,
    required this.total,
    required this.paid,
    required this.remaining,
  }) : super(key: key);

  final double total;
  final double paid;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line('total'.tr, total, bold: true),
          SizedBox(height: 6.h),
          _line('paidAmount'.tr, paid, color: Colors.green.shade700),
          SizedBox(height: 4.h),
          _line(
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
  }

  Widget _line(String label, double amount, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 15.sp : 13.sp,
          ),
        ),
        Text(
          SalesAmountFormat.display(amount),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 16.sp : 14.sp,
            color: color,
          ),
        ),
      ],
    );
  }
}
