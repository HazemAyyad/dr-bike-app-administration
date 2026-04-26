import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
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

    // Resolve current value safely for the dropdown.
    final String? dropdownValue =
        (_selectedSize?.isNotEmpty ?? false) && opts.contains(_selectedSize)
            ? _selectedSize
            : null;

    return Dialog(
      // Match the Add Product card background so the modal feels part of the
      // same design system (white in light, surface in dark).
      backgroundColor: AdminUiColors.cardBackground(context),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 500.w),
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── title ─────────────────────────────────────────────────
              Text(
                isEdit ? 'editSizeColor'.tr : 'addSizeColor'.tr,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              SizedBox(height: 16.h),

              // ── size dropdown — same CustomDropdownField used in the form
              CustomDropdownField(
                label: 'size',
                hint: 'sizeSelectHint',
                items: opts,
                value: dropdownValue,
                onChanged: (v) => setState(() => _selectedSize = v),
                isRequired: true,
              ),
              SizedBox(height: 12.h),

              // ── color Ar ──────────────────────────────────────────────
              CustomTextField(
                label: 'color',
                hintText: 'color',
                controller: _colorArCtrl,
                isRequired: true,
              ),
              SizedBox(height: 12.h),

              // ── color En ──────────────────────────────────────────────
              CustomTextField(
                label: 'colorEnglish',
                hintText: 'colorEnglish',
                controller: _colorEnCtrl,
              ),
              SizedBox(height: 12.h),

              // ── color Abbr (Hebrew) ───────────────────────────────────
              CustomTextField(
                label: 'colorHebrew',
                hintText: 'colorHebrew',
                controller: _colorAbbrCtrl,
              ),
              SizedBox(height: 12.h),

              // ── qty + price ───────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'quantity',
                      hintText: 'quantity',
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: CustomTextField(
                      label: 'price',
                      hintText: 'price',
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // ── wholesale + discount ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'wholesalePriceField',
                      hintText: 'wholesalePriceField',
                      controller: _wholesaleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: CustomTextField(
                      label: 'discountPercentage',
                      hintText: 'discountPercentage',
                      controller: _discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // ── buttons ───────────────────────────────────────────────
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
}
