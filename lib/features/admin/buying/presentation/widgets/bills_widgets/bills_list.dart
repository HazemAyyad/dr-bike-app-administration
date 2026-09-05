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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor4
                  : Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _PurchaseMonthDivider(month: month, count: bills.length),
                ...bills.map(
                  (bill) => _PurchaseBillCard(
                    bill: bill,
                    page: page,
                    totalText: _formatMoney(bill.finalTotal),
                    dateText: _formatDate(bill.createdAt),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        '$month · $count فواتير',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 13.sp,
            ),
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
      onTap: () {
        controller.getBillDetails(
          context: context,
          billId: bill.id.toString(),
        );
        Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: page);
      },
      child: Container(
        constraints: BoxConstraints(minHeight: 116.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Text('PUR-${bill.id}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900)),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(dateText,
                  style:
                      TextStyle(fontSize: 11.sp, color: Colors.grey.shade700)),
            ),
            _PurchaseStatusPill(
              label: _workflowLabel(bill.workflowStatus),
              color: AppColors.primaryColor,
            ),
          ]),
          SizedBox(height: 9.h),
          Row(children: [
            CircleAvatar(
              radius: 17.r,
              backgroundColor: AppColors.primaryColor.withValues(alpha: .08),
              child: const Icon(Icons.storefront_outlined,
                  color: AppColors.primaryColor, size: 18),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      bill.seller.trim().isEmpty
                          ? 'مصدر غير محدد'
                          : bill.seller,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w900)),
                  Text('${_sourceTypeLabel(bill)}  •  ${bill.itemsCount} أصناف',
                      style: TextStyle(
                          fontSize: 10.5.sp, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(totalText,
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
              Text(_paymentLabel(bill.paymentStatus),
                  style: TextStyle(
                      fontSize: 10.sp,
                      color: _paymentColor(bill.paymentStatus),
                      fontWeight: FontWeight.w800)),
            ]),
          ]),
          if ((double.tryParse(bill.remainingAmount) ?? 0) > 0 ||
              _issueSummaryText() != null) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                [
                  if ((double.tryParse(bill.remainingAmount) ?? 0) > 0)
                    'المتبقي: ${_formatMoney(bill.remainingAmount)}',
                  if (_issueSummaryText() != null) _issueSummaryText()!,
                ].join('  •  '),
                style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  String _formatMoney(String value) {
    final amount = double.tryParse(value) ?? 0;
    return '${intl.NumberFormat('#,##0.##').format(amount)} ${bill.currency}';
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
