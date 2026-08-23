import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/bills_models/bills_model.dart';
import '../../controllers/bills_controller.dart';

class BillsList extends GetView<BillsController> {
  const BillsList({
    Key? key,
    required this.bills,
    required this.month,
    required this.page,
  }) : super(key: key);

  final List<BillDataModel> bills;
  final String month;
  final String page;

  String _formatMoney(String value) {
    final amount = double.tryParse(value) ?? 0;
    return intl.NumberFormat("#,###.##").format(amount);
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return intl.DateFormat('yyyy/MM/dd').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          Text(
            month,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
          ),
          SizedBox(height: 8.h),
          ...bills.map(
            (bill) => _PurchaseBillCard(
              bill: bill,
              page: page,
              totalText: _formatMoney(bill.total),
              dateText: _formatDate(bill.createdAt),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseBillCard extends GetView<BillsController> {
  final BillDataModel bill;
  final String page;
  final String totalText;
  final String dateText;

  const _PurchaseBillCard({
    required this.bill,
    required this.page,
    required this.totalText,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () {
        controller.getBillDetails(
          context: context,
          billId: bill.id.toString(),
        );
        Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: page);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(32),
              blurRadius: 8.r,
              spreadRadius: 1.r,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'billNumber'.tr} #${bill.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: isDark
                                  ? AppColors.customGreyColor7
                                  : AppColors.customGreyColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                            ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        bill.seller.isEmpty ? 'مصدر غير معروف' : bill.seller,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: isDark
                                  ? AppColors.customGreyColor7
                                  : Colors.grey.shade700,
                              fontSize: 11.sp,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: AppColors.primaryColor,
                  size: 22.sp,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _BillInfoChip(
                  icon: Icons.calendar_today_outlined,
                  text: dateText,
                ),
                if (bill.status.isNotEmpty)
                  _BillInfoChip(
                    icon: Icons.flag_outlined,
                    text: bill.status,
                  ),
                _BillInfoChip(
                  icon: Icons.payments_outlined,
                  text: '$totalText ₪',
                  highlighted: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BillInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlighted;

  const _BillInfoChip({
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primaryColor : Colors.grey.shade700;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: color,
                  fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 10.sp,
                ),
          ),
        ],
      ),
    );
  }
}
