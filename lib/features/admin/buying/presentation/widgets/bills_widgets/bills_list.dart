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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const _PurchaseTableHeader(),
      ),
    );
  }
}

class _PurchaseTableHeader extends StatelessWidget {
  const _PurchaseTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      color: AppColors.primaryColor.withValues(alpha: 0.09),
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      child: const Row(
        children: [
          _HeaderCell('فاتورة', flex: 19),
          _HeaderCell('الإجمالي', flex: 27),
          _HeaderCell('القطع', flex: 11),
          _HeaderCell('الطرف', flex: 31),
          _HeaderCell('الحالة', flex: 22),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 11.sp,
            ),
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
        constraints: BoxConstraints(minHeight: 78.h),
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 19,
              child: _InvoiceCell(
                billId: bill.id,
                status: _invoiceStatusLabel(bill.status),
              ),
            ),
            Expanded(
              flex: 27,
              child: _AmountCell(
                total: totalText,
                remaining: _formatMoney(bill.remainingAmount),
                showRemaining: (double.tryParse(bill.remainingAmount) ?? 0) > 0,
              ),
            ),
            Expanded(
              flex: 11,
              child: _CompactTextCell(
                text: bill.itemsCount.toString(),
                weight: FontWeight.w800,
              ),
            ),
            Expanded(
              flex: 31,
              child: _PartyCell(
                name: bill.seller,
                typeLabel: _sourceTypeLabel(bill),
              ),
            ),
            Expanded(
              flex: 22,
              child: _StatusColumn(
                workflow: _workflowLabel(bill.workflowStatus),
                payment: _paymentLabel(bill.paymentStatus),
                paymentColor: _paymentColor(bill.paymentStatus),
                issueText: _issueSummaryText(),
              ),
            ),
          ],
        ),
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

  String _invoiceStatusLabel(String status) {
    switch (status) {
      case 'finished':
        return 'منتهية';
      case 'unfinished':
        return 'غير مكتملة';
      case 'cancelled':
        return 'ملغية';
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

class _InvoiceCell extends StatelessWidget {
  const _InvoiceCell({
    required this.billId,
    required this.status,
  });

  final int billId;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.sp,
                ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'PUR-$billId',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                fontSize: 9.sp,
              ),
        ),
      ],
    );
  }
}

class _CompactTextCell extends StatelessWidget {
  const _CompactTextCell({
    required this.text,
    this.weight = FontWeight.w600,
  });

  final String text;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 11.sp,
            fontWeight: weight,
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : Colors.black87,
          ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.total,
    required this.remaining,
    required this.showRemaining,
  });

  final String total;
  final String remaining;
  final bool showRemaining;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            total,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
          ),
        ),
        if (showRemaining) ...[
          SizedBox(height: 2.h),
          Text(
            'المتبقي:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 9.sp,
                  height: 1,
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            remaining,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10.sp,
                  height: 1,
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ],
    );
  }
}

class _PartyCell extends StatelessWidget {
  const _PartyCell({required this.name, required this.typeLabel});

  final String name;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final display =
        name.trim().isEmpty || name == 'no seller' ? 'غير محدد' : name.trim();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          display,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 12.sp,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
        ),
        SizedBox(height: 2.h),
        Text(
          typeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: 9.sp,
                height: 1,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
        ),
      ],
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.workflow,
    required this.payment,
    required this.paymentColor,
    required this.issueText,
  });

  final String workflow;
  final String payment;
  final Color paymentColor;
  final String? issueText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          workflow,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
        ),
        SizedBox(height: 2.h),
        Text(
          payment,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: paymentColor,
              ),
        ),
        if (issueText != null) ...[
          SizedBox(height: 2.h),
          Text(
            issueText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
          ),
        ],
      ],
    );
  }
}
