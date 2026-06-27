import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
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

class _MaintenanceDeliveryDialogState extends State<_MaintenanceDeliveryDialog> {
  final _paidCtrl = TextEditingController();
  ShownBoxesModel? _selectedBox;
  bool _loadingBoxes = true;

  @override
  void initState() {
    super.initState();
    _paidCtrl.text = SalesAmountFormat.display(widget.controller.invoiceTotal);
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    final boxes = await widget.controller.loadPaymentBoxes();
    if (!mounted) return;
    setState(() {
      _loadingBoxes = false;
      if (boxes.isNotEmpty) {
        _selectedBox = boxes.first;
      }
    });
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
      title: Text(
        'maintenanceDeliverAndPay'.tr,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
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
            SizedBox(height: 12.h),
            if (_loadingBoxes)
              const Center(child: CircularProgressIndicator())
            else if (widget.controller.paymentBoxes.isEmpty)
              Text(
                'noBoxesAvailable'.tr,
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12.sp),
              )
            else
              CustomDropdownFieldWithSearch(
                value: _selectedBox,
                isRequired: total > 0,
                tital: 'boxName'.tr,
                hint: 'boxName',
                items: widget.controller.paymentBoxes,
                onChanged: (v) => setState(() => _selectedBox = v as ShownBoxesModel?),
                itemAsString: (b) => (b as ShownBoxesModel).boxName,
                compareFn: (a, b) =>
                    (a as ShownBoxesModel).boxId == (b as ShownBoxesModel).boxId,
              ),
            SizedBox(height: 10.h),
            CustomTextField(
              controller: _paidCtrl,
              label: 'paidAmount'.tr,
              hintText: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      paymentBoxId: _selectedBox?.boxId,
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
