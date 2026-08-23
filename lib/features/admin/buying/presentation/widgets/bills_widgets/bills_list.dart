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
    return intl.NumberFormat('#,##0.00').format(amount);
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
  const _PurchaseBillCard({
    required this.bill,
    required this.page,
    required this.totalText,
    required this.dateText,
  });

  final BillDataModel bill;
  final String page;
  final String totalText;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () {
        controller.getBillDetails(
          context: context,
          billId: bill.id.toString(),
        );
        Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: page);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(32),
              blurRadius: 5.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primaryColor,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardInfoRow(
                            label: '${'billNumber'.tr} #${bill.id}',
                            value: dateText,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            bill.seller.isEmpty
                                ? 'مصدر غير معروف'
                                : bill.seller,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          SizedBox(height: 5.h),
                          Wrap(
                            spacing: 5.w,
                            runSpacing: 5.h,
                            children: [
                              if (bill.workflowStatus.isNotEmpty)
                                _BillInfoChip(
                                  icon: Icons.inventory_2_outlined,
                                  text: _workflowLabel(bill.workflowStatus),
                                ),
                              if (bill.paymentStatus.isNotEmpty)
                                _BillInfoChip(
                                  icon: Icons.payments_outlined,
                                  text: _paymentLabel(bill.paymentStatus),
                                ),
                              if (bill.status.isNotEmpty)
                                _BillInfoChip(
                                  icon: Icons.flag_outlined,
                                  text: bill.status,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(minWidth: 72.w, maxWidth: 110.w),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.customGreen1,
                borderRadius: Get.locale!.languageCode == 'en'
                    ? const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'total'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$totalText ₪',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _workflowLabel(String status) {
    switch (status) {
      case 'finalized':
        return 'مكتملة';
      case 'partially_received':
        return 'استلام جزئي';
      case 'awaiting_finalization':
        return 'بانتظار الاعتماد';
      case 'awaiting_receiving':
        return 'بانتظار الاستلام';
      default:
        return status;
    }
  }

  String _paymentLabel(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوعة';
      case 'partially_paid':
      case 'partial':
        return 'مدفوعة جزئياً';
      case 'unpaid':
        return 'غير مدفوعة';
      default:
        return status;
    }
  }
}

class _CardInfoRow extends StatelessWidget {
  const _CardInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ),
      ],
    );
  }
}

class _BillInfoChip extends StatelessWidget {
  const _BillInfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.primaryColor),
          SizedBox(width: 4.w),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                ),
          ),
        ],
      ),
    );
  }
}
