import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_dialog_shell.dart';

class InstantSalePriceDialogResult {
  final double retailPrice;
  final double wholesalePrice;

  const InstantSalePriceDialogResult({
    required this.retailPrice,
    required this.wholesalePrice,
  });
}

/// Retail price is required before adding to cart.
Future<InstantSalePriceDialogResult?> showInstantSalePriceDialog(
  ProductModel product,
) {
  final ctx = Get.context;
  if (ctx == null) return Future.value();

  return showDialog<InstantSalePriceDialogResult>(
    context: ctx,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) => _InstantSalePriceDialog(product: product),
  );
}

class _InstantSalePriceDialog extends StatefulWidget {
  const _InstantSalePriceDialog({required this.product});

  final ProductModel product;

  @override
  State<_InstantSalePriceDialog> createState() =>
      _InstantSalePriceDialogState();
}

class _InstantSalePriceDialogState extends State<_InstantSalePriceDialog> {
  late final TextEditingController _retailCtrl;

  @override
  void initState() {
    super.initState();
    _retailCtrl = TextEditingController();
    if (widget.product.unitPrice > 0) {
      _retailCtrl.text = _priceText(widget.product.unitPrice);
    }
  }

  @override
  void dispose() {
    _retailCtrl.dispose();
    super.dispose();
  }

  void _close([InstantSalePriceDialogResult? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(result);
  }

  void _onSave() {
    final retail = SalesAmountFormat.parse(_retailCtrl.text);
    if (retail <= 0) {
      Get.snackbar('error'.tr, 'instantSaleRetailPriceRequired'.tr);
      return;
    }
    _close(
      InstantSalePriceDialogResult(
        retailPrice: retail,
        wholesalePrice: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missingRetail = widget.product.unitPrice <= 0;

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
                'instantSaleEnterRetailPrice'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'instantSaleRetailRequiredHint'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                widget.product.nameAr,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: _retailCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSave(),
                decoration: InstantSaleDialogShell.fieldDecoration(
                  context,
                  labelText: missingRetail
                      ? '${'instantSaleRetailPriceLabel'.tr} *'
                      : 'instantSaleRetailPriceLabel'.tr,
                  hintText: '0',
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _close(),
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
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      child: Text('save'.tr),
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

String _priceText(double price) {
  if (price == price.roundToDouble()) {
    return price.toInt().toString();
  }
  return price.toStringAsFixed(2);
}
