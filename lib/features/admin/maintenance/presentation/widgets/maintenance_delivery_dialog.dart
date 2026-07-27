import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../controllers/maintenance_controller.dart';

Future<void> showMaintenanceDeliveryDialog(
  MaintenanceController controller,
) async {
  final ctx = Get.context;
  if (ctx == null) return;

  await showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (dialogCtx) => _MaintenanceDeliveryDialog(controller: controller),
  );
}

class _MaintenanceDeliveryDialog extends StatefulWidget {
  const _MaintenanceDeliveryDialog({required this.controller});

  final MaintenanceController controller;

  @override
  State<_MaintenanceDeliveryDialog> createState() =>
      _MaintenanceDeliveryDialogState();
}

class _MaintenanceDeliveryDialogState
    extends State<_MaintenanceDeliveryDialog> {
  final _cashCtrl = TextEditingController();
  final _visaCtrl = TextEditingController();
  final _transferCtrl = TextEditingController();
  final _visaNoteCtrl = TextEditingController();
  final _transferNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cashCtrl.text = SalesAmountFormat.display(widget.controller.invoiceTotal);
    for (final ctrl in [_cashCtrl, _visaCtrl, _transferCtrl]) {
      ctrl.addListener(_refreshTotals);
    }
  }

  @override
  void dispose() {
    for (final ctrl in [
      _cashCtrl,
      _visaCtrl,
      _transferCtrl,
      _visaNoteCtrl,
      _transferNoteCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _refreshTotals() => setState(() {});

  double get _cashAmount => SalesAmountFormat.parse(_cashCtrl.text);
  double get _visaAmount => SalesAmountFormat.parse(_visaCtrl.text);
  double get _transferAmount => SalesAmountFormat.parse(_transferCtrl.text);
  double get _paidTotal => _cashAmount + _visaAmount + _transferAmount;

  @override
  Widget build(BuildContext context) {
    final total = widget.controller.invoiceTotal;
    final remaining = (total - _paidTotal).clamp(0, double.infinity).toDouble();
    final isOverPaid = _paidTotal > total;

    return AlertDialog(
      backgroundColor: Colors.grey.shade100,
      surfaceTintColor: Colors.grey.shade100,
      title: Text(
        'maintenanceDeliverAndPay'.tr,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _totalRow('maintenancePartsTotal'.tr, widget.controller.partsTotal),
            _totalRow('maintenanceLaborCost'.tr, widget.controller.laborCost),
            if (widget.controller.discount > 0)
              _totalRow('discount'.tr, -widget.controller.discount),
            Divider(height: 16.h),
            _totalRow('total'.tr, total, bold: true),
            _totalRow('paidAmount'.tr, _paidTotal),
            _totalRow('remainingAmount'.tr, remaining, bold: remaining > 0),
            if (isOverPaid)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  'إجمالي الدفعات أكبر من قيمة الفاتورة',
                  style: TextStyle(
                    color: AppColors.redColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (total > 0) ...[
              SizedBox(height: 10.h),
              Obx(() {
                final isOpen = widget.controller.isMaintenanceDailyBoxOpen;
                final isLoading = widget.controller.isDailyBoxLoading.value;
                final color = isOpen ? AppColors.customGreen1 : Colors.blueGrey;
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: color,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          isOpen
                              ? 'صندوق الصيانة اليومي مفتوح'
                              : 'يجب فتح صندوق الصيانة اليومي قبل الدفع',
                          style: TextStyle(
                            color: color,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isOpen)
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : widget.controller.openMaintenanceDailySession,
                          child: isLoading
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('فتح'),
                        ),
                    ],
                  ),
                );
              }),
            ],
            SizedBox(height: 10.h),
            CustomTextField(
              controller: _cashCtrl,
              label: 'كاش',
              hintText: '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (_) => null,
            ),
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _visaCtrl,
              label: 'فيزا',
              hintText: '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (_) => null,
            ),
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _visaNoteCtrl,
              label: 'ملاحظة الفيزا',
              hintText: 'رقم العملية أو آخر 4 أرقام',
              validator: (_) => null,
            ),
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _transferCtrl,
              label: 'حوالة',
              hintText: '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (_) => null,
            ),
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _transferNoteCtrl,
              label: 'ملاحظة الحوالة',
              hintText: 'رقم الحوالة أو من مين وصلت',
              validator: (_) => null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        Obx(
          () => TextButton(
            onPressed: widget.controller.isLoading.value || isOverPaid
                ? null
                : () async {
                    final payments = _buildPayments();
                    final ok = await widget.controller.deliverMaintenance(
                      paymentAmount: _paidTotal,
                      payments: payments,
                    );
                    if (ok && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: widget.controller.isLoading.value
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'delivered'.tr,
                    style: const TextStyle(
                      color: AppColors.customGreen1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _buildPayments() {
    final payments = <Map<String, dynamic>>[];
    void addPayment(String method, double amount, String note) {
      if (amount <= 0) return;
      payments.add({
        'method': method,
        'amount': amount,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      });
    }

    addPayment('cash', _cashAmount, '');
    addPayment('visa', _visaAmount, _visaNoteCtrl.text);
    addPayment('bank_transfer', _transferAmount, _transferNoteCtrl.text);
    return payments;
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            SalesAmountFormat.display(value),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? AppColors.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
