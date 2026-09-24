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

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return intl.DateFormat('yyyy/MM/dd').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PurchaseMonthDivider(month: month, count: bills.length),
        ...bills.map(
          (bill) => _PurchaseBillCard(
            bill: bill,
            page: page,
            dateText: _formatDate(bill.createdAt),
          ),
        ),
        SizedBox(height: 7.h),
      ],
    );
  }
}

class PurchaseBillsTableHeader extends StatelessWidget {
  const PurchaseBillsTableHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(10.r),
          border:
              Border.all(color: AppColors.primaryColor.withValues(alpha: .18)),
        ),
        child: Row(children: [
          Icon(Icons.touch_app_outlined,
              color: AppColors.primaryColor, size: 21.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'اضغط على الفاتورة لعرض الأصناف والاستلام والدفعات',
              style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PurchaseMonthDivider extends StatelessWidget {
  const _PurchaseMonthDivider({required this.month, required this.count});

  final String month;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 18.h,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 7.w),
            Icon(
              Icons.calendar_month_outlined,
              size: 17.sp,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                month,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text('$count', style: TextStyle(fontSize: 10.sp)),
            ),
          ],
        ),
      );
}

class _PurchaseBillCard extends GetView<BillsController> {
  const _PurchaseBillCard({
    required this.bill,
    required this.page,
    required this.dateText,
  });

  final BillDataModel bill;
  final String page;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final statusColor = _workflowColor(bill.workflowStatus);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          controller.getBillDetails(
            context: context,
            billId: bill.id.toString(),
          );
          Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: page);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page == '2'
                      ? Icons.inventory_2_outlined
                      : Icons.receipt_long_outlined,
                  color: statusColor,
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bill.seller.trim().isEmpty
                                ? 'مصدر غير محدد'
                                : bill.seller,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          'PUR-${bill.id}',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$dateText • ${bill.itemsCount} أصناف',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Text(
                          '${_formatMoney(bill.finalTotal)} ${bill.currency}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 7.w),
                        _PurchaseStatusPill(
                          label: _workflowLabel(bill.workflowStatus),
                          color: statusColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 13.sp,
                          color: _paymentColor(bill.paymentStatus),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            [
                              _sourceTypeLabel(bill),
                              _paymentLabel(bill.paymentStatus),
                              if (_issueSummaryText() != null)
                                _issueSummaryText()!,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.chevron_left_rounded, size: 19.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(String value) {
    final amount = double.tryParse(value) ?? 0;
    return intl.NumberFormat('#,##0.##').format(amount);
  }

  String _formatQty(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  String _sourceTypeLabel(BillDataModel bill) {
    switch (bill.sourceType) {
      case 'seller':
        return 'مورد';
      case 'customer':
        return 'زبون';
      default:
        return 'غير محدد';
    }
  }

  String? _issueSummaryText() {
    final parts = <String>[];
    if (bill.missingQuantityTotal > 0) {
      parts.add('نقص ${_formatQty(bill.missingQuantityTotal)}');
    }
    if (bill.extraQuantityTotal > 0) {
      parts.add('زيادة ${_formatQty(bill.extraQuantityTotal)}');
    }
    if (bill.damagedQuantityTotal > 0) {
      parts.add('تالف ${_formatQty(bill.damagedQuantityTotal)}');
    }
    if (bill.mismatchedQuantityTotal > 0) {
      parts.add('غير مطابق ${_formatQty(bill.mismatchedQuantityTotal)}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
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

  Color _workflowColor(String status) {
    switch (status) {
      case 'finalized':
        return Colors.green.shade700;
      case 'partially_received':
        return Colors.deepOrange.shade700;
      case 'awaiting_finalization':
        return Colors.indigo;
      case 'awaiting_receiving':
        return Colors.orange.shade800;
      default:
        return AppColors.primaryColor;
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

  Color _paymentColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'partially_paid':
      case 'partial':
        return Colors.orange.shade800;
      case 'unpaid':
        return Colors.red.shade700;
      default:
        return AppColors.primaryColor;
    }
  }
}

class _PurchaseStatusPill extends StatelessWidget {
  const _PurchaseStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 9.5.sp, fontWeight: FontWeight.w900)),
      );
}
