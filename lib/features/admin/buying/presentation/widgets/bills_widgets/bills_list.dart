import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/services/initial_bindings.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/helpers/app_success_notice.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../data/models/bills_models/bills_model.dart';
import '../../controllers/bills_controller.dart';
import '../../utils/purchase_status_labels.dart';

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
        SizedBox(height: 4.h),
      ],
    );
  }
}

class PurchaseBillsTableHeader extends StatelessWidget {
  const PurchaseBillsTableHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(10.r),
          border:
              Border.all(color: AppColors.primaryColor.withValues(alpha: .18)),
        ),
        child: Row(children: [
          Icon(Icons.touch_app_outlined,
              color: AppColors.primaryColor, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'اضغط على الفاتورة لعرض الأصناف والاستلام والدفعات',
              style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 10.sp,
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
        padding: EdgeInsets.fromLTRB(12.w, 5.h, 12.w, 2.h),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 15.h,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 7.w),
            Icon(
              Icons.calendar_month_outlined,
              size: 15.sp,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                month,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
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
          margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.5.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
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
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page == '2'
                      ? Icons.inventory_2_outlined
                      : Icons.receipt_long_outlined,
                  color: statusColor,
                  size: 17.sp,
                ),
              ),
              SizedBox(width: 7.w),
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
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          'PUR-${bill.id}',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$dateText • ${bill.itemsCount} أصناف',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        _PurchaseStatusPill(
                          label: purchaseWorkflowLabel(bill.workflowStatus),
                          color: statusColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 12.sp,
                          color: _paymentColor(bill.paymentStatus),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            '${purchasePaymentStatusLabel(bill.paymentStatus)} • '
                            'الإجمالي ${_formatMoney(bill.finalTotal)} | '
                            'المدفوع ${_formatMoney(bill.paidAmount)} | '
                            'المتبقي ${_formatMoney(bill.remainingAmount)} '
                            '${_currencySymbol(bill.currency)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5.sp,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bill.isAwaitingApproval && canManagePurchases)
                    _approvalAction(context),
                  if (bill.isAwaitingApproval &&
                      canManagePurchases &&
                      bill.canQuickPay)
                    SizedBox(width: 3.w),
                  if (bill.canQuickPay)
                    _paymentAction(context)
                  else if (!bill.isAwaitingApproval &&
                      bill.paymentStatus == 'paid')
                    Icon(
                      Icons.check_circle_rounded,
                      size: 19.sp,
                      color: Colors.green.shade700,
                    )
                  else if (!bill.isAwaitingApproval)
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 17.sp,
                      color: Colors.grey,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentAction(BuildContext context) => Tooltip(
        message: 'تسجيل دفعة على الفاتورة',
        child: InkResponse(
          radius: 22.r,
          onTap: () => _showQuickPaymentSheet(context),
          child: Container(
            width: 31.w,
            height: 31.w,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_outlined,
              size: 17.sp,
              color: Colors.green.shade700,
            ),
          ),
        ),
      );

  Widget _approvalAction(BuildContext context) => Tooltip(
        message: bill.canQuickFinalize
            ? 'اعتماد الفاتورة'
            : 'عالج فروقات الاستلام قبل الاعتماد',
        child: InkResponse(
          radius: 22.r,
          onTap: () => _confirmQuickFinalize(context),
          child: Container(
            width: 31.w,
            height: 31.w,
            decoration: BoxDecoration(
              color: (bill.canQuickFinalize ? Colors.indigo : Colors.orange)
                  .withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fact_check_outlined,
              size: 17.sp,
              color: bill.canQuickFinalize
                  ? Colors.indigo.shade700
                  : Colors.orange.shade800,
            ),
          ),
        ),
      );

  String _formatMoney(String value) {
    final amount = double.tryParse(value) ?? 0;
    return intl.NumberFormat('#,##0.##').format(amount);
  }

  String _currencySymbol(String currency) {
    switch (currency.trim()) {
      case 'شيكل':
      case 'ILS':
        return '₪';
      case 'دولار':
      case 'USD':
        return r'$';
      case 'دينار':
      case 'JOD':
        return 'د.أ';
      default:
        return currency;
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

  Future<void> _confirmQuickFinalize(BuildContext context) async {
    if (!bill.canQuickFinalize) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('الفاتورة غير جاهزة للاعتماد'),
          content: const Text(
            'يوجد فرق أو ملاحظة غير معالجة في الاستلام. افتح الفاتورة وعالج الفروقات أولاً، وبعدها يمكنك اعتمادها.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اعتماد فاتورة الشراء'),
        content: Text(
          'سيتم اعتماد فاتورة PUR-${bill.id} بالمبلغ النهائي للبضاعة المستلمة. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('اعتماد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await controller.finalizePurchaseFromList(
      context,
      billId: bill.id.toString(),
    );
    if (!ok || !context.mounted) return;
    AppSuccessNotice.show(
      title: 'success'.tr,
      message: 'تم اعتماد فاتورة الشراء بنجاح.',
    );
  }

  Future<void> _showQuickPaymentSheet(BuildContext context) async {
    await controller.loadPurchaseBoxes();
    controller.preparePaymentAmount(amount: bill.remainingAmount);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          ThemeService.isDark.value ? AppColors.customGreyColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.w,
            14.h,
            16.w,
            MediaQuery.of(sheetContext).viewInsets.bottom + 14.h,
          ),
          child: GetBuilder<BillsController>(
            builder: (controller) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        color: Colors.green.shade700, size: 21.sp),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        'دفعة لفاتورة PUR-${bill.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '${bill.seller} • المتبقي ${_formatMoney(bill.remainingAmount)} ${_currencySymbol(bill.currency)}',
                  style:
                      TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<ShownBoxesModel>(
                  initialValue: controller.selectedPurchaseBox.value,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الصندوق',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: controller.purchaseBoxes
                      .map(
                        (box) => DropdownMenuItem<ShownBoxesModel>(
                          value: box,
                          child: Text('${box.boxName} (${box.currency})'),
                        ),
                      )
                      .toList(),
                  onChanged: controller.selectPurchaseBox,
                ),
                SizedBox(height: 9.h),
                TextField(
                  controller: controller.purchasePaymentAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المدفوع',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 9.h),
                TextField(
                  controller: controller.purchasePaymentNoteController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isWorkflowLoading.value
                        ? null
                        : () async {
                            final ok = await controller.payPurchaseBillFromList(
                              context,
                              bill: bill,
                            );
                            if (ok && sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                    icon: controller.isWorkflowLoading.value
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('تسجيل الدفعة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
