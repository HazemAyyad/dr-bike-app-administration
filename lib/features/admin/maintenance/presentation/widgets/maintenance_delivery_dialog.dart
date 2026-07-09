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
  final _paidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paidCtrl.text = SalesAmountFormat.display(widget.controller.invoiceTotal);
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.controller.invoiceTotal;

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
            SizedBox(height: 10.h),
            CustomTextField(
              controller: _paidCtrl,
              label: 'paidAmount'.tr,
              hintText: '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
            onPressed: widget.controller.isLoading.value
                ? null
                : () async {
                    final paid = SalesAmountFormat.parse(_paidCtrl.text);
                    final ok = await widget.controller.deliverMaintenance(
                      paymentAmount: paid,
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
