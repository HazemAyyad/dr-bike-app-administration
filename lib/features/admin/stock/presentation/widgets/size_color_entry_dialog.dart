import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../controllers/stock_controller.dart';

/// Modal for adding or editing a single size+color entry (Arabic color name only).
class SizeColorEntryDialog extends StatefulWidget {
  const SizeColorEntryDialog({
    Key? key,
    required this.controller,
    this.sizeIdx,
    this.colorIdx,
  }) : super(key: key);

  final StockController controller;
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
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _wholesaleCtrl;
  late final TextEditingController _discountCtrl;

  String? _selectedSize;
  XFile? _pendingImage;
  bool _clearImage = false;

  bool get isEdit => widget.sizeIdx != null && widget.colorIdx != null;

  StockController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final sz = c.items[widget.sizeIdx!];
      final col = sz.colors[widget.colorIdx!];
      _selectedSize = sz.sizeController.text.trim();
      _colorArCtrl = TextEditingController(text: col.colorController.text);
      _qtyCtrl = TextEditingController(text: col.quantityController.text);
      _priceCtrl = TextEditingController(text: col.priceController.text);
      _wholesaleCtrl =
          TextEditingController(text: col.wholesalePriceController.text);
      _discountCtrl =
          TextEditingController(text: col.discountController.text);
    } else {
      _colorArCtrl = TextEditingController();
      _qtyCtrl = TextEditingController();
      _priceCtrl = TextEditingController();
      _wholesaleCtrl = TextEditingController();
      _discountCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _colorArCtrl.dispose();
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

    final qtyErr = c.validateSizeColorQuantity(
      qty,
      excludeSizeIdx: isEdit ? widget.sizeIdx : null,
      excludeColorIdx: isEdit ? widget.colorIdx : null,
    );
    if (qtyErr != null) {
      Get.snackbar(
        'error'.tr,
        qtyErr.trParams({'stock': '${c.productStockTotal}'}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isEdit) {
      c.updateSizeColorEntry(
        sizeIdx: widget.sizeIdx!,
        colorIdx: widget.colorIdx!,
        size: size,
        colorAr: colorAr,
        colorEn: '',
        colorAbbr: '',
        qty: qty,
        price: price,
        wholesalePrice: _wholesaleCtrl.text.trim(),
        discount: _discountCtrl.text.trim(),
      );
      _applyImageToEntry(
        sizeIdx: widget.sizeIdx!,
        colorIdx: widget.colorIdx!,
      );
    } else {
      c.addSizeColorEntry(
        size: size,
        colorAr: colorAr,
        colorEn: '',
        colorAbbr: '',
        qty: qty,
        price: price,
        wholesalePrice: _wholesaleCtrl.text.trim(),
        discount: _discountCtrl.text.trim(),
      );
      final indices = _findEntryIndices(size, colorAr);
      if (indices != null) {
        _applyImageToEntry(
          sizeIdx: indices[0],
          colorIdx: indices[1],
        );
      }
    }
    Get.back();
  }

  List<int>? _findEntryIndices(String size, String colorAr) {
    for (var i = 0; i < c.items.length; i++) {
      final sz = c.items[i];
      if (sz.sizeController.text.trim() != size.trim()) continue;
      for (var j = 0; j < sz.colors.length; j++) {
        if (sz.colors[j].colorController.text.trim() == colorAr.trim()) {
          return [i, j];
        }
      }
    }
    return null;
  }

  void _applyImageToEntry({required int sizeIdx, required int colorIdx}) {
    if (_clearImage) {
      c.clearSizeColorImage(sizeIdx, colorIdx);
      return;
    }
    if (_pendingImage != null) {
      c.items[sizeIdx].colors[colorIdx].pendingImage = _pendingImage;
      c.items[sizeIdx].colors[colorIdx].clearImage = false;
      c.update();
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _pendingImage = picked;
      _clearImage = false;
    });
  }

  void _removeImage() {
    setState(() {
      _pendingImage = null;
      _clearImage = true;
    });
  }

  bool get _hasImagePreview {
    if (_pendingImage != null) return true;
    if (_clearImage) return false;
    if (!isEdit) return false;
    final url = c.items[widget.sizeIdx!].colors[widget.colorIdx!].existingImageUrl;
    return url != null && url.isNotEmpty;
  }

  String? get _existingImageUrl {
    if (!isEdit || _clearImage) return null;
    return c.items[widget.sizeIdx!].colors[widget.colorIdx!].existingImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final opts = List<String>.from(c.productSizeOptions);
    if (_selectedSize != null &&
        _selectedSize!.isNotEmpty &&
        !opts.contains(_selectedSize)) {
      opts.insert(0, _selectedSize!);
    }

    final String? dropdownValue =
        (_selectedSize?.isNotEmpty ?? false) && opts.contains(_selectedSize)
            ? _selectedSize
            : null;

    return Dialog(
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
              Text(
                isEdit ? 'editSizeColor'.tr : 'addSizeColor'.tr,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomDropdownField(
                      label: 'size',
                      hint: 'sizeSelectHint',
                      items: opts,
                      value: dropdownValue,
                      onChanged: (v) => setState(() => _selectedSize = v),
                      isRequired: true,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: CustomTextField(
                      label: 'color',
                      hintText: 'color',
                      controller: _colorArCtrl,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (context) {
                  final stock = c.productStockTotal;
                  final used = c.totalSizeColorQuantity(
                    excludeSizeIdx: isEdit ? widget.sizeIdx : null,
                    excludeColorIdx: isEdit ? widget.colorIdx : null,
                  );
                  final remaining = (stock - used).clamp(0, stock);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      'sizeColorQtyHint'.trParams({
                        'stock': '$stock',
                        'remaining': '$remaining',
                      }),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: 11.sp,
                          ),
                    ),
                  );
                },
              ),
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
                        decimal: true,
                      ),
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'wholesalePriceField',
                      hintText: 'wholesalePriceField',
                      controller: _wholesaleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: CustomTextField(
                      label: 'discountPercentage',
                      hintText: 'discountPercentage',
                      controller: _discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'addImage'.tr,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: AdminUiColors.subtleOverlay(context),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _pendingImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.file(
                                File(_pendingImage!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : (_existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.network(
                                    ShowNetImage.getPhoto(_existingImageUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 24.sp,
                                    ),
                                  ),
                                )
                              : Icon(Icons.add_a_photo_outlined, size: 24.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'sizeColorImageOptional'.tr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                        ),
                        if (_hasImagePreview) ...[
                          SizedBox(height: 8.h),
                          TextButton(
                            onPressed: _removeImage,
                            child: Text('removeImage'.tr),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
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
