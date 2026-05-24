import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/product_model.dart';
import '../../utils/sales_amount_format.dart';

class InstantSalePriceDialogResult {
  final double retailPrice;
  final double? wholesalePrice;

  const InstantSalePriceDialogResult({
    required this.retailPrice,
    this.wholesalePrice,
  });
}

/// Retail (+ optional wholesale) price entry for instant sale picker.
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
  State<_InstantSalePriceDialog> createState() => _InstantSalePriceDialogState();
}

class _InstantSalePriceDialogState extends State<_InstantSalePriceDialog> {
  late final TextEditingController _retailCtrl;
  late final TextEditingController _wholesaleCtrl;

  @override
  void initState() {
    super.initState();
    _retailCtrl = TextEditingController();
    _wholesaleCtrl = TextEditingController();
    if (widget.product.wholesalePrice > 0) {
      _wholesaleCtrl.text = _priceText(widget.product.wholesalePrice);
    }
  }

  @override
  void dispose() {
    _retailCtrl.dispose();
    _wholesaleCtrl.dispose();
    super.dispose();
  }

  void _close([InstantSalePriceDialogResult? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(result);
  }

  void _onSave() {
    final retail = SalesAmountFormat.parse(_retailCtrl.text);
    if (retail <= 0) {
      Get.snackbar('error'.tr, 'instantSalePriceRequired'.tr);
      return;
    }
    final wholesaleRaw = _wholesaleCtrl.text.trim();
    final wholesale =
        wholesaleRaw.isEmpty ? null : SalesAmountFormat.parse(wholesaleRaw);
    if (wholesale != null && wholesale <= 0) {
      Get.snackbar('error'.tr, 'instantSaleWholesaleInvalid'.tr);
      return;
    }
    _close(
      InstantSalePriceDialogResult(
        retailPrice: retail,
        wholesalePrice: wholesale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: Colors.grey.shade100,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h + bottomInset),
        child: SingleChildScrollView(
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
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'instantSaleRetailPriceLabel'.tr,
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _wholesaleCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSave(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'instantSaleWholesalePriceLabel'.tr,
                  hintText: 'instantSaleWholesaleOptional'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
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
                        backgroundColor: Colors.grey.shade800,
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
