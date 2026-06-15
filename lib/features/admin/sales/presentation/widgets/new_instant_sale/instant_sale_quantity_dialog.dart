import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import 'instant_sale_dialog_shell.dart';

Future<int?> showInstantSaleQuantityDialog(
  BuildContext context, {
  required int initialQuantity,
  required int maxQuantity,
}) {
  return showDialog<int>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => _InstantSaleQuantityDialog(
      initialQuantity: initialQuantity,
      maxQuantity: maxQuantity,
    ),
  );
}

class _InstantSaleQuantityDialog extends StatefulWidget {
  const _InstantSaleQuantityDialog({
    required this.initialQuantity,
    required this.maxQuantity,
  });

  final int initialQuantity;
  final int maxQuantity;

  @override
  State<_InstantSaleQuantityDialog> createState() =>
      _InstantSaleQuantityDialogState();
}

class _InstantSaleQuantityDialogState extends State<_InstantSaleQuantityDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialQuantity}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_controller.text.trim()) ?? 0;
    if (qty < 1) {
      Get.snackbar('error'.tr, 'invalidQuantity'.tr);
      return;
    }
    if (qty > widget.maxQuantity) {
      Get.snackbar('error'.tr, 'out_of_stock_products'.tr);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, qty);
  }

  @override
  Widget build(BuildContext context) {
    return InstantSaleDialogShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'quantity'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                scrollPadding: EdgeInsets.only(bottom: 120.h),
                decoration: InstantSaleDialogShell.fieldDecoration(
                  context,
                  labelText: 'quantity'.tr,
                  hintText: '1',
                ).copyWith(counterText: ''),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      child: Text('confirm'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
