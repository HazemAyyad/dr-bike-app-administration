import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
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
              totalText: _formatMoney(bill.finalTotal),
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
    final canReviewReceiving = _canReviewReceiving(bill);
    final paidText = _formatMoney(bill.paidAmount);
    final remainingText = _formatMoney(bill.remainingAmount);
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
                                  color: _paymentColor(bill.paymentStatus),
                                ),
                              if (bill.status.isNotEmpty)
                                _BillInfoChip(
                                  icon: Icons.flag_outlined,
                                  text: _invoiceStatusLabel(bill.status),
                                ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Wrap(
                            spacing: 5.w,
                            runSpacing: 5.h,
                            children: [
                              _BillInfoChip(
                                icon: Icons.done_all_outlined,
                                text: 'مدفوع $paidText',
                                color: Colors.green.shade700,
                              ),
                              if ((double.tryParse(bill.remainingAmount) ?? 0) >
                                  0)
                                _BillInfoChip(
                                  icon: Icons.pending_actions_outlined,
                                  text: 'متبقي $remainingText',
                                  color: Colors.deepOrange.shade700,
                                ),
                            ],
                          ),
                          if (bill.hasReceivingSummary) ...[
                            SizedBox(height: 5.h),
                            Wrap(
                              spacing: 5.w,
                              runSpacing: 5.h,
                              children: [
                                if (bill.missingQuantityTotal > 0)
                                  _BillInfoChip(
                                    icon: Icons.remove_circle_outline,
                                    text:
                                        'نقص ${_formatQty(bill.missingQuantityTotal)}',
                                    color: Colors.red.shade700,
                                  ),
                                if (bill.extraQuantityTotal > 0)
                                  _BillInfoChip(
                                    icon: Icons.add_circle_outline,
                                    text:
                                        'زيادة ${_formatQty(bill.extraQuantityTotal)}',
                                    color: Colors.indigo.shade700,
                                  ),
                                if (bill.damagedQuantityTotal > 0)
                                  _BillInfoChip(
                                    icon: Icons.broken_image_outlined,
                                    text:
                                        'تالف ${_formatQty(bill.damagedQuantityTotal)}',
                                    color: Colors.brown.shade700,
                                  ),
                                if (bill.mismatchedQuantityTotal > 0)
                                  _BillInfoChip(
                                    icon: Icons.compare_arrows_outlined,
                                    text:
                                        'غير مطابق ${_formatQty(bill.mismatchedQuantityTotal)}',
                                    color: Colors.purple.shade700,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (bill.canQuickPay)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: IconButton(
                  tooltip: 'تسجيل دفعة',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showQuickPaymentSheet(context),
                  icon: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.deepOrange.shade700,
                    size: 24.sp,
                  ),
                ),
              ),
            if (canReviewReceiving)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: IconButton(
                  tooltip: 'مراجعة الاستلام',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    controller.getBillDetails(
                      context: context,
                      billId: bill.id.toString(),
                    );
                    Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: '2');
                  },
                  icon: Icon(
                    Icons.fact_check_outlined,
                    color: AppColors.primaryColor,
                    size: 24.sp,
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

  bool _canReviewReceiving(BillDataModel bill) {
    final workflow = bill.workflowStatus.toLowerCase();
    final status = bill.status.toLowerCase();
    if (workflow == 'finalized' ||
        workflow == 'received' ||
        status == 'finished' ||
        status == 'cancelled') {
      return false;
    }
    return workflow.isEmpty ||
        workflow == 'awaiting_receiving' ||
        workflow == 'partially_received' ||
        workflow == 'awaiting_finalization' ||
        status == 'unfinished';
  }

  String _formatMoney(String value) {
    final amount = double.tryParse(value) ?? 0;
    return '${intl.NumberFormat('#,##0.##').format(amount)} ${bill.currency}';
  }

  String _formatQty(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
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

  Future<void> _showQuickPaymentSheet(BuildContext context) async {
    controller.preparePaymentAmount(amount: bill.remainingAmount);
    await controller.loadPurchaseBoxes();
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => _QuickPurchasePaymentSheet(bill: bill),
    );
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
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primaryColor).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color ?? AppColors.primaryColor),
          SizedBox(width: 4.w),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: color ?? AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickPurchasePaymentSheet extends GetView<BillsController> {
  const _QuickPurchasePaymentSheet({required this.bill});

  final BillDataModel bill;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h + bottom),
        child: GetBuilder<BillsController>(
          builder: (controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تسجيل دفعة لفاتورة #${bill.id}',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.sp,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _PaymentSummaryLine(
                  label: 'المتبقي',
                  value: '${_money(bill.remainingAmount)} ${bill.currency}',
                  color: Colors.deepOrange.shade700,
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<ShownBoxesModel>(
                  initialValue: controller.selectedPurchaseBox.value,
                  items: controller.purchaseBoxes
                      .map(
                        (box) => DropdownMenuItem<ShownBoxesModel>(
                          value: box,
                          child: Text('${box.boxName} - ${box.currency}'),
                        ),
                      )
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'الصندوق',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onChanged: controller.selectPurchaseBox,
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: controller.purchasePaymentAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'قيمة الدفعة',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: controller.purchasePaymentNoteController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: controller.isWorkflowLoading.value
                        ? null
                        : () async {
                            final ok = await controller.payPurchaseBillFromList(
                              context,
                              bill: bill,
                            );
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: controller.isWorkflowLoading.value
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('تسجيل الدفعة'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _money(String value) {
    final amount = double.tryParse(value) ?? 0;
    return intl.NumberFormat('#,##0.##').format(amount);
  }
}

class _PaymentSummaryLine extends StatelessWidget {
  const _PaymentSummaryLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions_outlined, size: 18.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
