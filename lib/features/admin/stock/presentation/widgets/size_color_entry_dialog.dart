import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../controllers/stock_controller.dart';

/// Modal for adding or editing a single size+color entry.
///
/// Usage — add:
///   SizeColorEntryDialog.show(controller);
///
/// Usage — edit:
///   SizeColorEntryDialog.show(controller, sizeIdx: i, colorIdx: j);
class SizeColorEntryDialog extends StatefulWidget {
  const SizeColorEntryDialog({
    Key? key,
    required this.controller,
    this.sizeIdx,
    this.colorIdx,
  }) : super(key: key);

  final StockController controller;

  /// If both are non-null we are editing an existing entry.
  final int? sizeIdx;
  final int? colorIdx;

  static void show(
    StockController controller, {
    int? sizeIdx,
    int? colorIdx,
  }) {
    Get.dialog(
      SizeColorEntryDialog(
        controller: controller,
        sizeIdx: sizeIdx,
        colorIdx: colorIdx,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<SizeColorEntryDialog> createState() => _SizeColorEntryDialogState();
}

class _SizeColorEntryDialogState extends State<SizeColorEntryDialog> {
  late final TextEditingController _colorArCtrl;
  late final TextEditingController _colorEnCtrl;
  late final TextEditingController _colorAbbrCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _wholesaleCtrl;
  late final TextEditingController _discountCtrl;

  String? _selectedSize;

  bool get isEdit => widget.sizeIdx != null && widget.colorIdx != null;

  StockController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final sz = c.items[widget.sizeIdx!];
      final col = sz.colors[widget.colorIdx!];
      _selectedSize = sz.sizeController.text.trim();
      _colorArCtrl =
          TextEditingController(text: col.colorController.text);
      _colorEnCtrl =
          TextEditingController(text: col.colorEnController.text);
      _colorAbbrCtrl =
          TextEditingController(text: col.colorAbbrController.text);
      _qtyCtrl =
          TextEditingController(text: col.quantityController.text);
      _priceCtrl =
          TextEditingController(text: col.priceController.text);
      _wholesaleCtrl =
          TextEditingController(text: col.wholesalePriceController.text);
      _discountCtrl =
          TextEditingController(text: col.discountController.text);
    } else {
      _colorArCtrl = TextEditingController();
      _colorEnCtrl = TextEditingController();
      _colorAbbrCtrl = TextEditingController();
      _qtyCtrl = TextEditingController();
      _priceCtrl = TextEditingController();
      _wholesaleCtrl = TextEditingController();
      _discountCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _colorArCtrl.dispose();
    _colorEnCtrl.dispose();
    _colorAbbrCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _wholesaleCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final size = (_selectedSize ?? '').trim();
    final colorAr = _colorArCtrl.text.trim();
    final qty = _qtyCtrl.text.trim();
    final price = _priceCtrl.text.trim();

    if (size.isEmpty) {
      Get.snackbar('error'.tr, 'sizeRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (colorAr.isEmpty) {
      Get.snackbar('error'.tr, 'colorArRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (qty.isEmpty) {
      Get.snackbar('error'.tr, 'quantityRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (price.isEmpty) {
      Get.snackbar('error'.tr, 'priceRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (isEdit) {
      c.updateSizeColorEntry(
        sizeIdx: widget.sizeIdx!,
        colorIdx: widget.colorIdx!,
        size: size,
        colorAr: colorAr,
        colorEn: _colorEnCtrl.text.trim(),
        colorAbbr: _colorAbbrCtrl.text.trim(),
        qty: qty,
        price: price,
        wholesalePrice: _wholesaleCtrl.text.trim(),
        discount: _discountCtrl.text.trim(),
      );
    } else {
      c.addSizeColorEntry(
        size: size,
        colorAr: colorAr,
        colorEn: _colorEnCtrl.text.trim(),
        colorAbbr: _colorAbbrCtrl.text.trim(),
        qty: qty,
        price: price,
        wholesalePrice: _wholesaleCtrl.text.trim(),
        discount: _discountCtrl.text.trim(),
      );
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final opts = List<String>.from(c.productSizeOptions);
    if (_selectedSize != null &&
        _selectedSize!.isNotEmpty &&
        !opts.contains(_selectedSize)) {
      opts.insert(0, _selectedSize!);
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(maxWidth: 500.w),
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── title ──────────────────────────────────────────────────
              Text(
                isEdit ? 'editSizeColor'.tr : 'addSizeColor'.tr,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 16.h),

              // ── size dropdown ───────────────────────────────────────────
              _label(context, 'size'.tr, required: true),
              SizedBox(height: 4.h),
              DropdownButtonFormField<String>(
                value: (_selectedSize?.isNotEmpty ?? false) &&
                        opts.contains(_selectedSize)
                    ? _selectedSize
                    : null,
                hint: Text('sizeSelectHint'.tr),
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AdminUiColors.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 10.h),
                  isDense: true,
                ),
                items: opts
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSize = v),
              ),
              SizedBox(height: 12.h),

              // ── color Ar ───────────────────────────────────────────────
              _field(context, _colorArCtrl, 'color'.tr, required: true),
              SizedBox(height: 10.h),

              // ── color En ───────────────────────────────────────────────
              _field(context, _colorEnCtrl, 'colorEnglish'.tr),
              SizedBox(height: 10.h),

              // ── color Abbr (Hebrew) ────────────────────────────────────
              _field(context, _colorAbbrCtrl, 'colorHebrew'.tr),
              SizedBox(height: 10.h),

              // ── qty + price ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _field(context, _qtyCtrl, 'quantity'.tr,
                        required: true,
                        keyboardType: TextInputType.number),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _field(context, _priceCtrl, 'price'.tr,
                        required: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true)),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // ── wholesale + discount ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _field(
                        context, _wholesaleCtrl, 'wholesalePriceField'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _field(
                        context, _discountCtrl, 'discountPercentage'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // ── buttons ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'save'.tr : 'add'.tr),
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

  Widget _label(BuildContext context, String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                      color: Colors.red, fontSize: 11.sp),
                )
              ]
            : [],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, label, required: required),
        SizedBox(height: 4.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AdminUiColors.inputFill(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            isDense: true,
          ),
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(fontSize: 12.sp),
        ),
      ],
    );
  }
}
