import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_variant_model.dart';
import '../../utils/sales_amount_format.dart';

class SalesVariantPickerResult {
  final ProductColorVariant variant;
  final ProductSizeVariant size;
  final int quantity;
  final double unitPrice;

  const SalesVariantPickerResult({
    required this.variant,
    required this.size,
    required this.quantity,
    required this.unitPrice,
  });
}

Future<SalesVariantPickerResult?> showSalesVariantPickerSheet({
  required BuildContext context,
  required ProductModel product,
}) {
  return showModalBottomSheet<SalesVariantPickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SalesVariantPickerSheet(product: product),
  );
}

class _SalesVariantPickerSheet extends StatefulWidget {
  const _SalesVariantPickerSheet({required this.product});

  final ProductModel product;

  @override
  State<_SalesVariantPickerSheet> createState() =>
      _SalesVariantPickerSheetState();
}

class _SalesVariantPickerSheetState extends State<_SalesVariantPickerSheet> {
  ProductSizeVariant? _selectedSize;
  ProductColorVariant? _selectedColor;
  final _qtyController = TextEditingController(text: '1');

  List<ProductSizeVariant> get sizes => widget.product.sizes;

  @override
  void initState() {
    super.initState();
    if (sizes.isNotEmpty) {
      _selectedSize = sizes.first;
      final colors = _selectedSize!.colorSizes;
      if (colors.isNotEmpty) {
        _selectedColor = colors.firstWhere(
          (c) => c.stock > 0,
          orElse: () => colors.first,
        );
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    final variant = _selectedColor;
    if (variant == null) return widget.product.unitPrice;
    if (variant.effectiveUnitPrice > 0) return variant.effectiveUnitPrice;
    return widget.product.unitPrice;
  }

  int get _stock => _selectedColor?.stock ?? 0;

  void _confirm() {
    final size = _selectedSize;
    final color = _selectedColor;
    if (size == null || color == null) {
      Get.snackbar('error'.tr, 'selectSizeColor'.tr);
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty < 1) {
      Get.snackbar('error'.tr, 'invalidQuantity'.tr);
      return;
    }
    if (qty > color.stock) {
      Get.snackbar('error'.tr, 'out_of_stock_products'.tr);
      return;
    }
    Navigator.of(context).pop(
      SalesVariantPickerResult(
        variant: color,
        size: size,
        quantity: qty,
        unitPrice: _unitPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'selectSizeColor'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: cs.onSurface),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                widget.product.nameAr,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'size'.tr,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: sizes.map((sz) {
                  final selected = _selectedSize?.id == sz.id;
                  return ChoiceChip(
                    label: Text(sz.size),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedSize = sz;
                        final colors = sz.colorSizes;
                        _selectedColor = colors.isEmpty
                            ? null
                            : colors.firstWhere(
                                (c) => c.stock > 0,
                                orElse: () => colors.first,
                              );
                      });
                    },
                    backgroundColor: AdminUiColors.subtleOverlay(context),
                    selectedColor: cs.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'color'.tr,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: (_selectedSize?.colorSizes ?? []).map((color) {
                  final selected = _selectedColor?.id == color.id;
                  final out = color.stock < 1;
                  return FilterChip(
                    avatar: color.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Image.network(
                              ShowNetImage.getPhoto(color.imageUrl),
                              width: 24.w,
                              height: 24.w,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.palette_outlined, size: 18.sp),
                            ),
                          )
                        : Icon(Icons.palette_outlined, size: 18.sp),
                    label: Text('${color.colorAr} (${color.stock})'),
                    selected: selected,
                    onSelected: out
                        ? null
                        : (_) => setState(() => _selectedColor = color),
                    backgroundColor: AdminUiColors.subtleOverlay(context),
                    selectedColor: cs.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: out ? Colors.grey : cs.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: _infoTile(
                      context,
                      'price'.tr,
                      SalesAmountFormat.displayShekel(_unitPrice),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _infoTile(
                      context,
                      'stock'.tr,
                      '$_stock',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 72.w,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'quantity'.tr,
                        isDense: true,
                        filled: true,
                        fillColor: AdminUiColors.inputFill(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: FilledButton(
                onPressed: _stock > 0 ? _confirm : null,
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, 46.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'addToCart'.tr,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
